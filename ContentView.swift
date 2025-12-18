import SwiftUI
import AppKit

struct ContentView: View {
    // MARK: - Constants
    
    /// Delay before showing start time alert (allows state to update)
    private static let startTimeAlertDelay: TimeInterval = 0.01
    
    /// Delay before showing near tier alert (allows state to update)
    private static let nearTierAlertDelay: TimeInterval = 0.1
    
    /// Delay before recalculating after amending time
    private static let recalculateDelay: TimeInterval = 0.1
    
    // MARK: - State
    
    @State private var timeInput: String = ""
    @State private var result: String = ""
    @State private var errorMessage: String = ""
    @State private var currentCalculationResult: CalculationResult?
    @State private var showingNearTierAlert = false
    @State private var showingStartTimeAlert = false
    @State private var nearTierWarning: CalculationResult.Warning?
    @State private var startTimeWarning: CalculationResult.Warning?
    @State private var selectedNoteType: NoteType = .progressNote
    @State private var suggestedTimeRange: String = ""
    @State private var preserveSuggestedRange: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Billing Time Calculator")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
            
            VStack(alignment: .leading, spacing: 15) {
                // Note Type Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Note Type:")
                        .font(.headline)
                    
                    HStack(spacing: 20) {
                        RadioButton(title: "Progress Note", isSelected: selectedNoteType == .progressNote) {
                            if selectedNoteType != .progressNote {
                                selectedNoteType = .progressNote
                                // Recalculate with new note type if time input exists
                                if !timeInput.isEmpty {
                                    calculateCalls()
                                } else {
                                    clearPreviousResults()
                                }
                            }
                        }
                        RadioButton(title: "Consult", isSelected: selectedNoteType == .consult) {
                            if selectedNoteType != .consult {
                                selectedNoteType = .consult
                                // Recalculate with new note type if time input exists
                                if !timeInput.isEmpty {
                                    calculateCalls()
                                } else {
                                    clearPreviousResults()
                                }
                            }
                        }
                    }
                }
                
                Divider()
                
                // Time Input
                VStack(alignment: .leading, spacing: 10) {
                    Text("Enter time range (24h or 12h format):")
                        .font(.headline)
                    
                           TextField("e.g., 09:00-10:30, 0900-1030, or 9:00 AM-10:30 AM", text: $timeInput)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .onSubmit {
                            calculateCalls()
                        }
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .padding(.horizontal)
            
            Button("Calculate Calls") {
                calculateCalls()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            if !result.isEmpty {
                ScrollView {
                    VStack(spacing: 15) {
                        Divider()
                            .padding(.vertical)
                        
                        // Result Section
                        VStack(spacing: 10) {
                            HStack {
                                Text("Result:")
                                    .font(.headline)
                                Spacer()
                                Button(action: copyResultNumber) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "doc.on.doc")
                                        Text("Copy Number")
                                    }
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                            
                            Text(result)
                                .font(.system(.title2, design: .monospaced))
                                .foregroundColor(.blue)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                            
                            // Calculation Details
                            if let calcResult = currentCalculationResult {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Calculation Details:")
                                        .font(.headline)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text("Duration:")
                                                .fontWeight(.medium)
                                            Spacer()
                                            Text("\(calcResult.duration) minutes")
                                                .font(.system(.body, design: .monospaced))
                                        }
                                        
                                        HStack {
                                            Text("Time Range:")
                                                .fontWeight(.medium)
                                            Spacer()
                                            Text("\(calcResult.startTime.formattedString) - \(calcResult.endTime.formattedString)")
                                                .font(.system(.body, design: .monospaced))
                                        }
                                        
                                        if let matchedTier = calcResult.matchedTier {
                                            HStack {
                                                Text("Matched Tier:")
                                                    .fontWeight(.medium)
                                                Spacer()
                                                Text(matchedTier.description)
                                                    .font(.system(.body, design: .monospaced))
                                            }
                                        }
                                    }
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                            
                            // Suggested time range (if available)
                            if !suggestedTimeRange.isEmpty {
                                VStack(spacing: 8) {
                                    HStack {
                                        Text("Suggested Time Range:")
                                            .font(.headline)
                                        Spacer()
                                        Button(action: copySuggestedTimeRange) {
                                            HStack(spacing: 4) {
                                                Image(systemName: "doc.on.doc")
                                                Text("Copy Range")
                                            }
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                        }
                                        .buttonStyle(.bordered)
                                        .controlSize(.small)
                                    }
                                    
                                    Text(suggestedTimeRange)
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundColor(.green)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.green.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        
                        // Billing Table Section
                        if let calcResult = currentCalculationResult {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Billing Table (\(selectedNoteType == .progressNote ? "Progress Note" : "Consult")):")
                                    .font(.headline)
                                
                                billingTableView(for: calcResult.noteType, matchedTier: calcResult.matchedTier)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 850, minHeight: 850)
        .alert("Near Next Tier", isPresented: $showingNearTierAlert) {
            Button("Amend Time") {
                if case .nearNextTier(_, _, _, let suggestedEndTime) = nearTierWarning {
                    amendTimeForNextTier(suggestedEndTime: suggestedEndTime)
                }
            }
            Button("Keep Current", role: .cancel) {
                showResult()
            }
        } message: {
            if case .nearNextTier(let currentCalls, let nextCalls, let minutesToNext, let suggestedEndTime) = nearTierWarning {
                Text("You're only \(minutesToNext) minute\(minutesToNext == 1 ? "" : "s") away from the next tier (\(nextCalls) calls).\n\nCurrent: \(currentCalls) calls\nSuggested end time: \(suggestedEndTime)")
            } else {
                Text("")
            }
        }
        .alert("Start Time Not Aligned", isPresented: $showingStartTimeAlert) {
            Button("Amend Time") {
                if case .startTimeNotOnHourOrHalfHour(let suggestedStartTime) = startTimeWarning {
                    amendStartTime(suggestedStartTime: suggestedStartTime)
                }
            }
            Button("Keep Current", role: .cancel) {
                showResult()
            }
        } message: {
            if case .startTimeNotOnHourOrHalfHour(let suggestedStartTime) = startTimeWarning {
                Text("Start time should be on the hour (e.g., 09:00) or half-hour (e.g., 09:30).\n\nSuggested start time: \(suggestedStartTime)")
            } else {
                Text("")
            }
        }
    }
    
    private func calculateCalls() {
        errorMessage = ""
        result = ""
        currentCalculationResult = nil
        nearTierWarning = nil
        startTimeWarning = nil
        showingNearTierAlert = false
        showingStartTimeAlert = false
        
        // Only clear suggestedTimeRange if we're not preserving it (i.e., not after an amend)
        if !preserveSuggestedRange {
            suggestedTimeRange = ""
        }
        preserveSuggestedRange = false
        
        let calculator = BillingCalculator()
        let calculationResult = calculator.calculate(from: timeInput, noteType: selectedNoteType)
        
        switch calculationResult {
        case .success(let calcResult):
            currentCalculationResult = calcResult
            
            // Process warnings in order: start time first, then near tier
            let warningsToShow = calcResult.warnings
            
            // Show result first (so it's visible even when warnings are present)
            showResult()
            
            // Find start time warning
            if let startTimeWarning = warningsToShow.first(where: {
                if case .startTimeNotOnHourOrHalfHour = $0 { return true }
                return false
            }) {
                self.startTimeWarning = startTimeWarning
                // Extract suggested time range
                if case .startTimeNotOnHourOrHalfHour(let suggestedStartTime) = startTimeWarning {
                    self.suggestedTimeRange = "\(suggestedStartTime)-\(calcResult.endTime.formattedString)"
                }
                // Use a small delay to ensure state is fully updated
                DispatchQueue.main.asyncAfter(deadline: .now() + Self.startTimeAlertDelay) {
                    self.showingStartTimeAlert = true
                }
                return
            }
            
            // Find near tier warning
            if let nearTierWarning = warningsToShow.first(where: {
                if case .nearNextTier = $0 { return true }
                return false
            }) {
                // Set the warning first
                self.nearTierWarning = nearTierWarning
                // Extract suggested time range
                if case .nearNextTier(_, _, _, let suggestedEndTime) = nearTierWarning {
                    self.suggestedTimeRange = "\(calcResult.startTime.formattedString)-\(suggestedEndTime)"
                }
                // Use a small delay to ensure state is fully updated before showing alert
                DispatchQueue.main.asyncAfter(deadline: .now() + Self.nearTierAlertDelay) {
                    self.showingNearTierAlert = true
                }
                return
            }
            
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
    
    private func showResult() {
        guard let calcResult = currentCalculationResult else { return }
        result = "\(calcResult.calls) calls"
    }
    
    private func clearPreviousResults() {
        // Clear all previous calculation results when note type changes
        result = ""
        errorMessage = ""
        currentCalculationResult = nil
        nearTierWarning = nil
        startTimeWarning = nil
        showingNearTierAlert = false
        showingStartTimeAlert = false
        suggestedTimeRange = ""
        preserveSuggestedRange = false
    }
    
    private func copyResultNumber() {
        guard let calcResult = currentCalculationResult else { return }
        let numberString = "\(calcResult.calls)"
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(numberString, forType: .string)
    }
    
    private func copySuggestedTimeRange() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(suggestedTimeRange, forType: .string)
    }
    
    private func amendTimeForNextTier(suggestedEndTime: String) {
        guard let calcResult = currentCalculationResult else { return }
        let amendedRange = "\(calcResult.startTime.formattedString)-\(suggestedEndTime)"
        timeInput = amendedRange
        
        // Set the suggested time range to the amended range and preserve it
        suggestedTimeRange = amendedRange
        preserveSuggestedRange = true
        
        // Recalculate with amended time
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.recalculateDelay) {
            calculateCalls()
            // After recalculation, update suggestedTimeRange to match the current input
            self.suggestedTimeRange = self.timeInput
        }
    }
    
    private func amendStartTime(suggestedStartTime: String) {
        guard let calcResult = currentCalculationResult else { return }
        let amendedRange = "\(suggestedStartTime)-\(calcResult.endTime.formattedString)"
        timeInput = amendedRange
        
        // Set the suggested time range to the amended range and preserve it
        suggestedTimeRange = amendedRange
        preserveSuggestedRange = true
        
        // Recalculate with amended time
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.recalculateDelay) {
            calculateCalls()
            // After recalculation, update suggestedTimeRange to match the current input
            self.suggestedTimeRange = self.timeInput
        }
    }
    
    // MARK: - Billing Table View
    
    @ViewBuilder
    private func billingTableView(for noteType: NoteType, matchedTier: CalculationResult.BillingTier?) -> some View {
        let table = BillingCalculator.getBillingTable(for: noteType)
        
        VStack(spacing: 0) {
            // Table Header
            HStack(spacing: 0) {
                if noteType == .progressNote {
                    Text("Max Minutes")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .fontWeight(.semibold)
                        .padding(8)
                    Text("Actual Minutes")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .fontWeight(.semibold)
                        .padding(8)
                } else {
                    Text("Min Minutes")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .fontWeight(.semibold)
                        .padding(8)
                    Text("Max Minutes")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .fontWeight(.semibold)
                        .padding(8)
                }
                Text("Calls")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .fontWeight(.semibold)
                    .padding(8)
            }
            .background(Color.blue.opacity(0.2))
            
            // Table Rows
            ForEach(Array(table.enumerated()), id: \.offset) { index, tier in
                let isMatched = matchedTier?.calls == tier.calls
                
                HStack(spacing: 0) {
                    if noteType == .progressNote {
                        Text("\(tier.maxMinutes ?? 0)")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(8)
                        Text("\(tier.actualMinutes ?? 0)")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(8)
                    } else {
                        Text("\(tier.minMinutes ?? 0)")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(8)
                        Text("\(tier.maxMinutes ?? 0)")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(8)
                    }
                    Text("\(tier.calls)")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .fontWeight(isMatched ? .bold : .regular)
                        .padding(8)
                }
                .background(isMatched ? Color.green.opacity(0.3) : (index % 2 == 0 ? Color.gray.opacity(0.05) : Color.clear))
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.gray.opacity(0.2)),
                    alignment: .bottom
                )
            }
        }
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    ContentView()
}

