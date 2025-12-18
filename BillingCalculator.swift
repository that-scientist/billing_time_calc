import Foundation

/// Represents the type of medical note being billed
enum NoteType: CaseIterable, Identifiable {
    case progressNote
    case consult
    
    var id: String {
        switch self {
        case .progressNote: return "progressNote"
        case .consult: return "consult"
        }
    }
}

/// Represents a time of day with hours and minutes
struct Time: Equatable {
    let hours: Int
    let minutes: Int
    
    /// Converts time to total minutes since midnight
    var totalMinutes: Int {
        hours * 60 + minutes
    }
    
    /// Formats time as HH:MM string
    var formattedString: String {
        String(format: "%02d:%02d", hours, minutes)
    }
    
    /// Creates a Time from total minutes since midnight
    static func from(minutes: Int) -> Time {
        Time(hours: minutes / 60, minutes: minutes % 60)
    }
}

/// Result of a billing calculation
struct CalculationResult {
    let calls: Int
    let duration: Int
    let startTime: Time
    let endTime: Time
    let warnings: [Warning]
    let matchedTier: BillingTier?
    let noteType: NoteType
    
    /// Warning types that may be generated during calculation
    enum Warning {
        case nearNextTier(currentCalls: Int, nextCalls: Int, minutesToNext: Int, suggestedEndTime: String)
        case startTimeNotOnHourOrHalfHour(suggestedStartTime: String)
    }
    
    /// Represents a billing tier entry
    struct BillingTier {
        let calls: Int
        let minMinutes: Int?
        let maxMinutes: Int?
        let actualMinutes: Int?
        
        var description: String {
            if let actual = actualMinutes, let max = maxMinutes {
                return "Max: \(max) min, Actual: \(actual) min"
            } else if let min = minMinutes, let max = maxMinutes {
                return "\(min)-\(max) min"
            } else {
                return "\(calls) calls"
            }
        }
    }
}

/// Calculates billing calls based on time ranges and note types
struct BillingCalculator {
    // MARK: - Constants
    
    /// Warning window in minutes (user will be warned if within this many minutes of next tier)
    private static let warningWindowMinutes = 10
    
    /// Minimum duration for consult notes (minutes)
    private static let consultMinimumDuration = 61
    
    /// Maximum duration for consult notes (minutes)
    private static let consultMaximumDuration = 180
    
    /// Maximum duration for progress notes (minutes)
    private static let progressNoteMaximumDuration = 165
    
    // MARK: - Lookup Tables
    
    /// Progress Note lookup table: (maxMinutes, actualMinutes, calls)
    static let progressNoteTable: [(max: Int, actual: Int, calls: Int)] = [
        (30, 24, 3),
        (45, 36, 4),
        (60, 48, 5),
        (75, 60, 6),
        (90, 72, 7),
        (105, 84, 8),
        (120, 96, 9),
        (135, 108, 10),
        (150, 120, 11),
        (165, 132, 12)
    ]
    
    /// Consult Note lookup table: (minMinutes, maxMinutes, calls)
    /// Based on "Time Spent with Patient" ranges
    static let consultTable: [(min: Int, max: Int, calls: Int)] = [
        (61, 71, 1),
        (72, 86, 2),
        (87, 101, 3),
        (102, 116, 4),
        (117, 131, 5),
        (132, 146, 6),
        (147, 161, 7),
        (162, 176, 8),
        (177, 180, 9)
    ]
    
    /// Gets the billing table for a given note type
    static func getBillingTable(for noteType: NoteType) -> [CalculationResult.BillingTier] {
        switch noteType {
        case .progressNote:
            return progressNoteTable.map { entry in
                CalculationResult.BillingTier(
                    calls: entry.calls,
                    minMinutes: nil,
                    maxMinutes: entry.max,
                    actualMinutes: entry.actual
                )
            }
        case .consult:
            return consultTable.map { entry in
                CalculationResult.BillingTier(
                    calls: entry.calls,
                    minMinutes: entry.min,
                    maxMinutes: entry.max,
                    actualMinutes: nil
                )
            }
        }
    }
    
    /// Errors that can occur during billing calculation
    enum CalculationError: LocalizedError {
        case invalidFormat
        case invalidTime
        case startAfterEnd
        case durationTooLong
        case durationTooShort
        
        var errorDescription: String? {
            switch self {
            case .invalidFormat:
                return "Invalid format. Use HH:MM-HH:MM, HHMM-HHMM, or 12h format (e.g., 09:00-10:30, 0900-1030, 9:00 AM-10:30 AM)"
            case .invalidTime:
                return "Invalid time values. Use 24h format (00:00-23:59 or 0000-2359) or 12h format (1:00 AM-11:59 PM, with or without colons)"
            case .startAfterEnd:
                return "Start time must be before end time"
            case .durationTooLong:
                return "Duration exceeds maximum"
            case .durationTooShort:
                return "Consult notes require a duration that matches the billing table (61-180 minutes)"
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Calculates billing calls from a time range string
    /// - Parameters:
    ///   - input: Time range in format "HH:MM-HH:MM" or "HHMM-HHMM" (24h) or "H:MM AM/PM-H:MM AM/PM" (12h)
    ///   - noteType: Type of note (Progress Note or Consult)
    /// - Returns: Result containing calculation result or error
    
    func calculate(from input: String, noteType: NoteType) -> Result<CalculationResult, CalculationError> {
        // Parse the input
        let components = input.trimmingCharacters(in: .whitespaces).components(separatedBy: "-")
        guard components.count == 2 else {
            return .failure(.invalidFormat)
        }
        
        let startTimeString = components[0].trimmingCharacters(in: .whitespaces)
        let endTimeString = components[1].trimmingCharacters(in: .whitespaces)
        
        guard let startTime = parseTime(startTimeString),
              let endTime = parseTime(endTimeString) else {
            return .failure(.invalidTime)
        }
        
        // Calculate duration in minutes
        let duration = calculateDuration(start: startTime, end: endTime)
        
        guard duration >= 0 else {
            return .failure(.startAfterEnd)
        }
        
        // Check minimum duration for consult notes
        if noteType == .consult && duration < Self.consultMinimumDuration {
            return .failure(.durationTooShort)
        }
        
        // Check max duration based on note type
        let maxDuration = noteType == .consult ? Self.consultMaximumDuration : Self.progressNoteMaximumDuration
        guard duration <= maxDuration else {
            let error = CalculationError.durationTooLong
            // Note: We can't customize the error message here easily, but the validation works
            return .failure(error)
        }
        
        // Find the appropriate number of calls based on note type
        let (calls, matchedTier) = findCallsWithTier(for: duration, noteType: noteType)
        
        // For consult notes, verify the duration matches a table entry exactly
        if noteType == .consult && calls == 0 {
            return .failure(.durationTooShort) // Duration doesn't match any table entry
        }
        
        // Check for warnings
        var warnings: [CalculationResult.Warning] = []
        
        // Check if duration is within warning window of next tier (for both note types)
        if let nextTierWarning = checkNearNextTier(duration: duration, currentCalls: calls, startTime: startTime, noteType: noteType) {
            warnings.append(nextTierWarning)
        }
        
        // Check if start time is not on hour or half-hour (only for Progress Notes)
        if noteType == .progressNote {
            if let startTimeWarning = checkStartTimeAlignment(startTime: startTime) {
                warnings.append(startTimeWarning)
            }
        }
        
        return .success(CalculationResult(
            calls: calls,
            duration: duration,
            startTime: startTime,
            endTime: endTime,
            warnings: warnings,
            matchedTier: matchedTier,
            noteType: noteType
        ))
    }
    
    // MARK: - Private Methods
    
    /// Parses a time string into hours and minutes
    /// - Parameter timeString: Time string in various formats (12h or 24h, with or without colons)
    /// - Returns: Time struct or nil if parsing fails
    private func parseTime(_ timeString: String) -> Time? {
        let trimmed = timeString.trimmingCharacters(in: .whitespaces).uppercased()
        
        // Check for 12-hour format (contains AM or PM, or A.M./P.M.)
        let is12Hour = trimmed.contains("AM") || trimmed.contains("PM") || 
                       trimmed.contains("A.M.") || trimmed.contains("P.M.")
        
        if is12Hour {
            // Parse 12-hour format (e.g., "9:30 AM", "1:45 PM", "12:00 PM", "9:00AM", "9:00 a.m.")
            var timePart = trimmed
            var period = ""
            
            // Handle various AM/PM formats
            if trimmed.hasSuffix("AM") || trimmed.hasSuffix("A.M.") {
                if trimmed.hasSuffix("A.M.") {
                    timePart = String(trimmed.dropLast(4).trimmingCharacters(in: .whitespaces))
                } else {
                    timePart = String(trimmed.dropLast(2).trimmingCharacters(in: .whitespaces))
                }
                period = "AM"
            } else if trimmed.hasSuffix("PM") || trimmed.hasSuffix("P.M.") {
                if trimmed.hasSuffix("P.M.") {
                    timePart = String(trimmed.dropLast(4).trimmingCharacters(in: .whitespaces))
                } else {
                    timePart = String(trimmed.dropLast(2).trimmingCharacters(in: .whitespaces))
                }
                period = "PM"
            } else {
                // Try to find AM/PM in the middle (e.g., "9:00 AM" with extra spaces)
                let amIndex = trimmed.range(of: "AM") ?? trimmed.range(of: "A.M.")
                let pmIndex = trimmed.range(of: "PM") ?? trimmed.range(of: "P.M.")
                
                if let amRange = amIndex {
                    timePart = String(trimmed[..<amRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                    period = "AM"
                } else if let pmRange = pmIndex {
                    timePart = String(trimmed[..<pmRange.lowerBound]).trimmingCharacters(in: .whitespaces)
                    period = "PM"
                } else {
                    return nil
                }
            }
            
            // Parse time part (handle both "9:30" and "0930" formats)
            let components: [String]
            if timePart.contains(":") {
                components = timePart.components(separatedBy: ":")
            } else if timePart.count == 3 || timePart.count == 4 {
                // Handle "930" or "0930" format (3 or 4 digits)
                if timePart.count == 3 {
                    // "930" -> "9:30"
                    let hourStr = String(timePart.prefix(1))
                    let minStr = String(timePart.suffix(2))
                    components = [hourStr, minStr]
                } else {
                    // "0930" -> "09:30"
                    let hourStr = String(timePart.prefix(2))
                    let minStr = String(timePart.suffix(2))
                    components = [hourStr, minStr]
                }
            } else {
                return nil
            }
            
            guard components.count == 2,
                  let hours12 = Int(components[0]),
                  let minutes = Int(components[1]) else {
                return nil
            }
            
            guard hours12 >= 1 && hours12 <= 12 && minutes >= 0 && minutes <= 59 else {
                return nil
            }
            
            // Convert to 24-hour format
            var hours24 = hours12
            if period == "AM" {
                if hours12 == 12 {
                    hours24 = 0  // 12:xx AM becomes 00:xx
                }
            } else { // PM
                if hours12 != 12 {
                    hours24 = hours12 + 12  // 1-11 PM becomes 13-23
                }
                // 12 PM stays as 12
            }
            
            return Time(hours: hours24, minutes: minutes)
        } else {
            // Parse 24-hour format (handle both "09:00" and "0900" formats)
            let components: [String]
            if trimmed.contains(":") {
                components = trimmed.components(separatedBy: ":")
            } else if trimmed.count == 3 || trimmed.count == 4 {
                // Handle "900" or "0900" format (3 or 4 digits)
                if trimmed.count == 3 {
                    // "900" -> "9:00"
                    let hourStr = String(trimmed.prefix(1))
                    let minStr = String(trimmed.suffix(2))
                    components = [hourStr, minStr]
                } else {
                    // "0900" -> "09:00"
                    let hourStr = String(trimmed.prefix(2))
                    let minStr = String(trimmed.suffix(2))
                    components = [hourStr, minStr]
                }
            } else {
                return nil
            }
            
            guard components.count == 2,
                  let hours = Int(components[0]),
                  let minutes = Int(components[1]) else {
                return nil
            }
            
            guard hours >= 0 && hours <= 23 && minutes >= 0 && minutes <= 59 else {
                return nil
            }
            
            return Time(hours: hours, minutes: minutes)
        }
    }
    
    /// Calculates duration in minutes between two times
    private func calculateDuration(start: Time, end: Time) -> Int {
        end.totalMinutes - start.totalMinutes
    }
    
    private func findCalls(for duration: Int, noteType: NoteType) -> Int {
        let (calls, _) = findCallsWithTier(for: duration, noteType: noteType)
        return calls
    }
    
    private func findCallsWithTier(for duration: Int, noteType: NoteType) -> (Int, CalculationResult.BillingTier?) {
        switch noteType {
        case .progressNote:
            // Find the first entry where duration (actual face-to-face time) <= entry.actual
            // The actual time is what the doctor records, and max is what can be billed (actual * 1.25)
            // Table is ordered by actual time ascending, so first match is the correct tier
            for entry in Self.progressNoteTable {
                if duration <= entry.actual {
                    let tier = CalculationResult.BillingTier(
                        calls: entry.calls,
                        minMinutes: nil,
                        maxMinutes: entry.max,
                        actualMinutes: entry.actual
                    )
                    return (entry.calls, tier)
                }
            }
            // If duration exceeds all entries, return the maximum
            if let lastEntry = Self.progressNoteTable.last {
                let tier = CalculationResult.BillingTier(
                    calls: lastEntry.calls,
                    minMinutes: nil,
                    maxMinutes: lastEntry.max,
                    actualMinutes: lastEntry.actual
                )
                return (lastEntry.calls, tier)
            }
            return (12, nil)
            
        case .consult:
            // Find the entry where duration falls within the min-max range (exact table match only)
            for entry in Self.consultTable {
                if duration >= entry.min && duration <= entry.max {
                    let tier = CalculationResult.BillingTier(
                        calls: entry.calls,
                        minMinutes: entry.min,
                        maxMinutes: entry.max,
                        actualMinutes: nil
                    )
                    return (entry.calls, tier)
                }
            }
            // If duration doesn't match any table entry, return 0 (will be caught as error)
            return (0, nil)
        }
    }
    
    private func findNextTier(currentCalls: Int, noteType: NoteType) -> (max: Int, calls: Int)? {
        switch noteType {
        case .progressNote:
            // Find the next tier with MORE calls than current
            // For progress notes, we need to find the first entry with calls > currentCalls
            for entry in Self.progressNoteTable {
                if entry.calls > currentCalls {
                    return (max: entry.actual, calls: entry.calls)  // Use actual time, not max
                }
            }
            return nil
            
        case .consult:
            // Find the next tier with MORE calls than current
            // For consult notes, we need to find the first entry with calls > currentCalls
            // Return the min value (threshold to reach next tier)
            for entry in Self.consultTable {
                if entry.calls > currentCalls {
                    return (max: entry.min, calls: entry.calls)  // Use min as the threshold
                }
            }
            return nil
        }
    }
    
    /// Checks if duration is within warning window of next tier
    private func checkNearNextTier(duration: Int, currentCalls: Int, startTime: Time, noteType: NoteType) -> CalculationResult.Warning? {
        guard let nextTier = findNextTier(currentCalls: currentCalls, noteType: noteType) else {
            return nil // Already at max tier
        }
        
        let minutesToNext: Int
        let targetMinutes: Int
        switch noteType {
        case .progressNote:
            // For progress notes, use the next tier's actual time from findNextTier
            // The nextTier.max contains the actual time (face-to-face time needed)
            targetMinutes = nextTier.max
            minutesToNext = targetMinutes - duration
        case .consult:
            // For consult, use the next tier's minimum (which is stored in nextTier.max)
            targetMinutes = nextTier.max  // nextTier.max contains the min threshold for consult
            minutesToNext = targetMinutes - duration
        }
        
        if minutesToNext > 0 && minutesToNext <= Self.warningWindowMinutes {
            // Calculate suggested end time to reach next tier
            let suggestedEndTime = Time.from(minutes: startTime.totalMinutes + targetMinutes)
            
            return .nearNextTier(
                currentCalls: currentCalls,
                nextCalls: nextTier.calls,
                minutesToNext: minutesToNext,
                suggestedEndTime: suggestedEndTime.formattedString
            )
        }
        return nil
    }
    
    /// Checks if start time is aligned to hour or half-hour boundaries
    private func checkStartTimeAlignment(startTime: Time) -> CalculationResult.Warning? {
        // Check if start time is on hour (minutes == 0) or half-hour (minutes == 30)
        if startTime.minutes != 0 && startTime.minutes != 30 {
            // Suggest rounding to nearest hour or half-hour
            let suggestedTime: Time
            if startTime.minutes < 15 {
                suggestedTime = Time(hours: startTime.hours, minutes: 0)
            } else if startTime.minutes < 45 {
                suggestedTime = Time(hours: startTime.hours, minutes: 30)
            } else {
                // If minutes >= 45, round up to next hour
                let suggestedHours = (startTime.hours + 1) % 24
                suggestedTime = Time(hours: suggestedHours, minutes: 0)
            }
            return .startTimeNotOnHourOrHalfHour(suggestedStartTime: suggestedTime.formattedString)
        }
        return nil
    }
}

