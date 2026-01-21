"""
Billing Calculator - Core calculation logic for medical billing time calculator.
Converts time ranges to billing calls based on lookup tables.
"""

from dataclasses import dataclass
from enum import Enum
from typing import Optional, List, Tuple
import re


class NoteType(Enum):
    """Represents the type of medical note being billed"""
    PROGRESS_NOTE = "progressNote"
    CONSULT = "consult"


@dataclass
class Time:
    """Represents a time of day with hours and minutes"""
    hours: int
    minutes: int
    
    def total_minutes(self) -> int:
        """Converts time to total minutes since midnight"""
        return self.hours * 60 + self.minutes
    
    def formatted_string(self) -> str:
        """Formats time as HH:MM string"""
        return f"{self.hours:02d}:{self.minutes:02d}"
    
    @staticmethod
    def from_minutes(minutes: int) -> 'Time':
        """Creates a Time from total minutes since midnight"""
        return Time(hours=minutes // 60, minutes=minutes % 60)


@dataclass
class BillingTier:
    """Represents a billing tier entry"""
    calls: int
    min_minutes: Optional[int]
    max_minutes: Optional[int]
    actual_minutes: Optional[int]
    
    def description(self) -> str:
        """Returns a description of the tier"""
        if self.actual_minutes is not None and self.max_minutes is not None:
            return f"Max: {self.max_minutes} min, Actual: {self.actual_minutes} min"
        elif self.min_minutes is not None and self.max_minutes is not None:
            return f"{self.min_minutes}-{self.max_minutes} min"
        else:
            return f"{self.calls} calls"


class Warning:
    """Warning types that may be generated during calculation"""
    @dataclass
    class NearNextTier:
        current_calls: int
        next_calls: int
        minutes_to_next: int
        suggested_end_time: str
    
    @dataclass
    class StartTimeNotOnHourOrHalfHour:
        suggested_start_time: str


@dataclass
class CalculationResult:
    """Result of a billing calculation"""
    calls: int
    duration: int
    start_time: Time
    end_time: Time
    warnings: List[Warning]
    matched_tier: Optional[BillingTier]
    note_type: NoteType


class CalculationError(Exception):
    """Errors that can occur during billing calculation"""
    pass


class BillingCalculator:
    """Calculates billing calls based on time ranges and note types"""
    
    # Constants
    WARNING_WINDOW_MINUTES = 10
    CONSULT_MINIMUM_DURATION = 61
    CONSULT_MAXIMUM_DURATION = 180
    PROGRESS_NOTE_MAXIMUM_DURATION = 165
    
    # Progress Note lookup table: (maxMinutes, actualMinutes, calls)
    PROGRESS_NOTE_TABLE = [
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
    
    # Consult Note lookup table: (minMinutes, maxMinutes, calls)
    CONSULT_TABLE = [
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
    
    @classmethod
    def get_billing_table(cls, note_type: NoteType) -> List[BillingTier]:
        """Gets the billing table for a given note type"""
        if note_type == NoteType.PROGRESS_NOTE:
            return [
                BillingTier(
                    calls=entry[2],
                    min_minutes=None,
                    max_minutes=entry[0],
                    actual_minutes=entry[1]
                )
                for entry in cls.PROGRESS_NOTE_TABLE
            ]
        else:  # CONSULT
            return [
                BillingTier(
                    calls=entry[2],
                    min_minutes=entry[0],
                    max_minutes=entry[1],
                    actual_minutes=None
                )
                for entry in cls.CONSULT_TABLE
            ]
    
    def calculate(self, input_str: str, note_type: NoteType) -> CalculationResult:
        """
        Calculates billing calls from a time range string
        
        Args:
            input_str: Time range in format "HH:MM-HH:MM", "HH:MM to HH:MM", 
                      or 12h format with AM/PM
            note_type: Type of note (Progress Note or Consult)
        
        Returns:
            CalculationResult containing calculation result
        
        Raises:
            CalculationError: If input is invalid
        """
        # Parse the input - handle both "-" and " to " as separators
        trimmed_input = input_str.strip()
        
        # Use regex to split on either "-" or " to " (case insensitive)
        pattern = r"\s+to\s+|-"
        match = re.search(pattern, trimmed_input, re.IGNORECASE)
        
        if not match:
            raise CalculationError(
                "Invalid format. Use HH:MM-HH:MM or HH:MM to HH:MM, "
                "or 12h format (e.g., 09:00-10:30, 09:00 to 10:30, 9:00 AM to 10:30 AM)"
            )
        
        start_time_str = trimmed_input[:match.start()].strip()
        end_time_str = trimmed_input[match.end():].strip()
        
        start_time = self._parse_time(start_time_str)
        end_time = self._parse_time(end_time_str)
        
        if start_time is None or end_time is None:
            raise CalculationError(
                "Invalid time values. Use 24h format (00:00-23:59 or 0000-2359) "
                "or 12h format (1:00 AM-11:59 PM, with or without colons)"
            )
        
        # Calculate duration in minutes
        duration = self._calculate_duration(start_time, end_time)
        
        if duration < 0:
            raise CalculationError("Start time must be before end time")
        
        # Check minimum duration for consult notes
        if note_type == NoteType.CONSULT and duration < self.CONSULT_MINIMUM_DURATION:
            raise CalculationError(
                "Consult notes require a duration that matches the billing table (61-180 minutes)"
            )
        
        # Check max duration based on note type
        max_duration = (
            self.CONSULT_MAXIMUM_DURATION 
            if note_type == NoteType.CONSULT 
            else self.PROGRESS_NOTE_MAXIMUM_DURATION
        )
        if duration > max_duration:
            raise CalculationError("Duration exceeds maximum")
        
        # Find the appropriate number of calls based on note type
        calls, matched_tier = self._find_calls_with_tier(duration, note_type)
        
        # For consult notes, verify the duration matches a table entry exactly
        if note_type == NoteType.CONSULT and calls == 0:
            raise CalculationError(
                "Consult notes require a duration that matches the billing table (61-180 minutes)"
            )
        
        # Check for warnings
        warnings: List[Warning] = []
        
        # Check if duration is within warning window of next tier
        next_tier_warning = self._check_near_next_tier(
            duration, calls, start_time, note_type
        )
        if next_tier_warning:
            warnings.append(next_tier_warning)
        
        # Check if start time is not on hour or half-hour (only for Progress Notes)
        if note_type == NoteType.PROGRESS_NOTE:
            start_time_warning = self._check_start_time_alignment(start_time)
            if start_time_warning:
                warnings.append(start_time_warning)
        
        return CalculationResult(
            calls=calls,
            duration=duration,
            start_time=start_time,
            end_time=end_time,
            warnings=warnings,
            matched_tier=matched_tier,
            note_type=note_type
        )
    
    def _parse_time(self, time_string: str) -> Optional[Time]:
        """Parses a time string into hours and minutes"""
        trimmed = time_string.strip().upper()
        
        # Check for 12-hour format (contains AM or PM)
        is_12_hour = any(x in trimmed for x in ["AM", "PM", "A.M.", "P.M."])
        
        if is_12_hour:
            # Parse 12-hour format
            time_part = trimmed
            period = ""
            
            # Handle various AM/PM formats
            if trimmed.endswith("A.M."):
                time_part = trimmed[:-4].strip()
                period = "AM"
            elif trimmed.endswith("P.M."):
                time_part = trimmed[:-4].strip()
                period = "PM"
            elif trimmed.endswith("AM"):
                time_part = trimmed[:-2].strip()
                period = "AM"
            elif trimmed.endswith("PM"):
                time_part = trimmed[:-2].strip()
                period = "PM"
            else:
                # Try to find AM/PM in the middle
                am_match = re.search(r"\b(AM|A\.M\.)\b", trimmed)
                pm_match = re.search(r"\b(PM|P\.M\.)\b", trimmed)
                
                if am_match:
                    time_part = trimmed[:am_match.start()].strip()
                    period = "AM"
                elif pm_match:
                    time_part = trimmed[:pm_match.start()].strip()
                    period = "PM"
                else:
                    return None
            
            # Parse time part (handle both "9:30" and "0930" formats)
            if ":" in time_part:
                components = time_part.split(":")
            elif len(time_part) in [3, 4]:
                # Handle "930" or "0930" format
                if len(time_part) == 3:
                    components = [time_part[0], time_part[1:3]]
                else:
                    components = [time_part[0:2], time_part[2:4]]
            else:
                return None
            
            if len(components) != 2:
                return None
            
            try:
                hours_12 = int(components[0])
                minutes = int(components[1])
            except ValueError:
                return None
            
            if not (1 <= hours_12 <= 12 and 0 <= minutes <= 59):
                return None
            
            # Convert to 24-hour format
            if period == "AM":
                hours_24 = 0 if hours_12 == 12 else hours_12
            else:  # PM
                hours_24 = hours_12 if hours_12 == 12 else hours_12 + 12
            
            return Time(hours=hours_24, minutes=minutes)
        else:
            # Parse 24-hour format
            if ":" in trimmed:
                components = trimmed.split(":")
            elif len(trimmed) in [3, 4]:
                # Handle "900" or "0900" format
                if len(trimmed) == 3:
                    components = [trimmed[0], trimmed[1:3]]
                else:
                    components = [trimmed[0:2], trimmed[2:4]]
            else:
                return None
            
            if len(components) != 2:
                return None
            
            try:
                hours = int(components[0])
                minutes = int(components[1])
            except ValueError:
                return None
            
            if not (0 <= hours <= 23 and 0 <= minutes <= 59):
                return None
            
            return Time(hours=hours, minutes=minutes)
    
    def _calculate_duration(self, start: Time, end: Time) -> int:
        """Calculates duration in minutes between two times"""
        return end.total_minutes() - start.total_minutes()
    
    def _find_calls_with_tier(
        self, duration: int, note_type: NoteType
    ) -> Tuple[int, Optional[BillingTier]]:
        """Finds the number of calls and matched tier for a given duration"""
        if note_type == NoteType.PROGRESS_NOTE:
            # Find the tier where duration falls
            # Match based on max (billing time), not actual (face-to-face time)
            best_match = None
            for entry in self.PROGRESS_NOTE_TABLE:
                if duration <= entry[0]:  # max minutes (billing time)
                    tier = BillingTier(
                        calls=entry[2],
                        min_minutes=None,
                        max_minutes=entry[0],
                        actual_minutes=entry[1]
                    )
                    best_match = (entry[2], tier)
                    break  # Found the matching tier
            
            if best_match:
                return best_match
            
            # If duration is less than all entries, return the first tier
            if self.PROGRESS_NOTE_TABLE:
                first_entry = self.PROGRESS_NOTE_TABLE[0]
                tier = BillingTier(
                    calls=first_entry[2],
                    min_minutes=None,
                    max_minutes=first_entry[0],
                    actual_minutes=first_entry[1]
                )
                return (first_entry[2], tier)
            
            return (3, None)
        else:  # CONSULT
            # Find the entry where duration falls within the min-max range
            for entry in self.CONSULT_TABLE:
                if entry[0] <= duration <= entry[1]:
                    tier = BillingTier(
                        calls=entry[2],
                        min_minutes=entry[0],
                        max_minutes=entry[1],
                        actual_minutes=None
                    )
                    return (entry[2], tier)
            
            # If duration doesn't match any table entry, return 0
            return (0, None)
    
    def _find_next_tier(
        self, current_calls: int, note_type: NoteType
    ) -> Optional[Tuple[int, int]]:
        """Finds the next tier with more calls than current"""
        if note_type == NoteType.PROGRESS_NOTE:
            for entry in self.PROGRESS_NOTE_TABLE:
                if entry[2] > current_calls:
                    return (entry[1], entry[2])  # actual minutes, calls
            return None
        else:  # CONSULT
            for entry in self.CONSULT_TABLE:
                if entry[2] > current_calls:
                    return (entry[0], entry[2])  # min threshold, calls
            return None
    
    def _check_near_next_tier(
        self, duration: int, current_calls: int, start_time: Time, note_type: NoteType
    ) -> Optional[Warning.NearNextTier]:
        """Checks if duration is within warning window of next tier"""
        next_tier = self._find_next_tier(current_calls, note_type)
        if not next_tier:
            return None  # Already at max tier
        
        target_minutes = next_tier[0]
        minutes_to_next = target_minutes - duration
        
        if 0 < minutes_to_next <= self.WARNING_WINDOW_MINUTES:
            suggested_end_time = Time.from_minutes(
                start_time.total_minutes() + target_minutes
            )
            
            return Warning.NearNextTier(
                current_calls=current_calls,
                next_calls=next_tier[1],
                minutes_to_next=minutes_to_next,
                suggested_end_time=suggested_end_time.formatted_string()
            )
        
        return None
    
    def _check_start_time_alignment(
        self, start_time: Time
    ) -> Optional[Warning.StartTimeNotOnHourOrHalfHour]:
        """Checks if start time is aligned to hour or half-hour boundaries"""
        if start_time.minutes not in [0, 30]:
            # Suggest rounding to nearest hour or half-hour
            if start_time.minutes < 15:
                suggested_time = Time(hours=start_time.hours, minutes=0)
            elif start_time.minutes < 45:
                suggested_time = Time(hours=start_time.hours, minutes=30)
            else:
                # If minutes >= 45, round up to next hour
                suggested_hours = (start_time.hours + 1) % 24
                suggested_time = Time(hours=suggested_hours, minutes=0)
            
            return Warning.StartTimeNotOnHourOrHalfHour(
                suggested_start_time=suggested_time.formatted_string()
            )
        
        return None
