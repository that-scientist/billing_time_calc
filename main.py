"""
Billing Time Calculator - Windows GUI Application
A medical billing time calculator with a Tkinter interface.
"""

import tkinter as tk
from tkinter import ttk, messagebox, scrolledtext
import threading
from datetime import datetime
from typing import Optional
import pyperclip  # For clipboard operations

from billing_calculator import (
    BillingCalculator,
    NoteType,
    CalculationResult,
    CalculationError,
    Warning
)


class BillingTimeCalcApp:
    """Main application window"""
    
    def __init__(self, root):
        self.root = root
        self.root.title("Billing Time Calculator")
        self.root.geometry("900x900")
        self.root.minsize(850, 850)
        
        # State variables
        self.time_input = tk.StringVar(value="")
        self.result_text = tk.StringVar(value="")
        self.error_message = tk.StringVar(value="")
        self.selected_note_type = NoteType.PROGRESS_NOTE
        self.current_calculation_result: Optional[CalculationResult] = None
        self.suggested_time_range = tk.StringVar(value="")
        self.start_time_warning_shown = False
        
        # Timer state
        self.timer_start_time: Optional[datetime] = None
        self.is_timer_running = False
        self.timer_label: Optional[tk.Label] = None
        
        # Calculator instance
        self.calculator = BillingCalculator()
        
        self._create_widgets()
        self._center_window()
    
    def _center_window(self):
        """Center the window on the screen"""
        self.root.update_idletasks()
        width = self.root.winfo_width()
        height = self.root.winfo_height()
        x = (self.root.winfo_screenwidth() // 2) - (width // 2)
        y = (self.root.winfo_screenheight() // 2) - (height // 2)
        self.root.geometry(f"{width}x{height}+{x}+{y}")
    
    def _create_widgets(self):
        """Create and layout all UI widgets"""
        # Main container
        main_frame = ttk.Frame(self.root, padding="20")
        main_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)
        main_frame.columnconfigure(0, weight=1)
        
        # Title
        title_label = ttk.Label(
            main_frame,
            text="Billing Time Calculator",
            font=("Arial", 18, "bold")
        )
        title_label.grid(row=0, column=0, pady=(0, 20))
        
        # Note Type Selection
        note_type_frame = ttk.LabelFrame(main_frame, text="Note Type", padding="10")
        note_type_frame.grid(row=1, column=0, sticky=(tk.W, tk.E), pady=(0, 15))
        
        self.note_type_var = tk.StringVar(value="progressNote")
        progress_radio = ttk.Radiobutton(
            note_type_frame,
            text="Progress Note",
            variable=self.note_type_var,
            value="progressNote",
            command=self._on_note_type_changed
        )
        progress_radio.grid(row=0, column=0, padx=10)
        
        consult_radio = ttk.Radiobutton(
            note_type_frame,
            text="Consult",
            variable=self.note_type_var,
            value="consult",
            command=self._on_note_type_changed
        )
        consult_radio.grid(row=0, column=1, padx=10)
        
        # Time Input Section
        input_frame = ttk.LabelFrame(main_frame, text="Time Input", padding="10")
        input_frame.grid(row=2, column=0, sticky=(tk.W, tk.E), pady=(0, 15))
        input_frame.columnconfigure(0, weight=1)
        
        input_label = ttk.Label(
            input_frame,
            text="Enter time range (24h or 12h format):"
        )
        input_label.grid(row=0, column=0, sticky=tk.W, pady=(0, 5))
        
        input_entry_frame = ttk.Frame(input_frame)
        input_entry_frame.grid(row=1, column=0, sticky=(tk.W, tk.E), pady=(0, 5))
        input_entry_frame.columnconfigure(0, weight=1)
        
        self.time_entry = ttk.Entry(
            input_entry_frame,
            textvariable=self.time_input,
            font=("Courier", 11),
            width=50
        )
        self.time_entry.grid(row=0, column=0, sticky=(tk.W, tk.E), padx=(0, 10))
        self.time_entry.bind("<Return>", lambda e: self._calculate_calls())
        self.time_entry.bind("<KeyRelease>", self._on_input_change)
        
        # Timer button
        self.timer_button = ttk.Button(
            input_entry_frame,
            text="Start Timer",
            command=self._toggle_timer,
            width=15
        )
        self.timer_button.grid(row=0, column=1)
        
        # Timer label (initially hidden)
        self.timer_label = ttk.Label(
            input_frame,
            text="",
            font=("Courier", 10),
            foreground="green"
        )
        self.timer_label.grid(row=2, column=0, sticky=tk.W, pady=(5, 0))
        
        # Error message
        self.error_label = ttk.Label(
            input_frame,
            textvariable=self.error_message,
            foreground="red",
            font=("Arial", 9)
        )
        self.error_label.grid(row=3, column=0, sticky=tk.W, pady=(5, 0))
        
        # Calculate button
        calculate_button = ttk.Button(
            main_frame,
            text="Calculate Calls",
            command=self._calculate_calls,
            width=20
        )
        calculate_button.grid(row=3, column=0, pady=(0, 15))
        
        # Result Section
        result_frame = ttk.LabelFrame(main_frame, text="Result", padding="10")
        result_frame.grid(row=4, column=0, sticky=(tk.W, tk.E, tk.N, tk.S), pady=(0, 15))
        result_frame.columnconfigure(0, weight=1)
        result_frame.rowconfigure(1, weight=1)
        main_frame.rowconfigure(4, weight=1)
        
        # Result header with copy buttons
        result_header = ttk.Frame(result_frame)
        result_header.grid(row=0, column=0, sticky=(tk.W, tk.E), pady=(0, 10))
        
        result_title = ttk.Label(result_header, text="Result:", font=("Arial", 12, "bold"))
        result_title.grid(row=0, column=0, sticky=tk.W)
        
        button_frame = ttk.Frame(result_header)
        button_frame.grid(row=0, column=1, sticky=tk.E)
        
        copy_full_button = ttk.Button(
            button_frame,
            text="Copy Full",
            command=self._copy_full_result,
            width=12
        )
        copy_full_button.grid(row=0, column=0, padx=(0, 5))
        
        copy_number_button = ttk.Button(
            button_frame,
            text="Copy Number",
            command=self._copy_result_number,
            width=12
        )
        copy_number_button.grid(row=0, column=1)
        
        result_header.columnconfigure(1, weight=1)
        
        # Result display
        self.result_display = ttk.Label(
            result_frame,
            textvariable=self.result_text,
            font=("Courier", 16),
            foreground="blue",
            background="#E3F2FD",
            padding="10",
            anchor="center"
        )
        self.result_display.grid(row=1, column=0, sticky=(tk.W, tk.E), pady=(0, 10))
        
        # Details and table container (scrollable)
        details_container = ttk.Frame(result_frame)
        details_container.grid(row=2, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        details_container.columnconfigure(0, weight=1)
        details_container.rowconfigure(0, weight=1)
        result_frame.rowconfigure(2, weight=1)
        
        # Scrollable text area for details and table
        self.details_text = scrolledtext.ScrolledText(
            details_container,
            wrap=tk.WORD,
            font=("Courier", 9),
            height=15,
            state=tk.DISABLED
        )
        self.details_text.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
    
    def _on_note_type_changed(self):
        """Handle note type selection change"""
        if self.note_type_var.get() == "progressNote":
            self.selected_note_type = NoteType.PROGRESS_NOTE
        else:
            self.selected_note_type = NoteType.CONSULT
        
        # Recalculate if time input exists
        if self.time_input.get():
            self._calculate_calls()
        else:
            self._clear_previous_results()
    
    def _on_input_change(self, event=None):
        """Handle input field changes"""
        # Clear error when user starts typing
        if self.error_message.get():
            self.error_message.set("")
    
    def _calculate_calls(self):
        """Calculate billing calls from time input"""
        self.error_message.set("")
        self.result_text.set("")
        self.current_calculation_result = None
        self.suggested_time_range.set("")
        self.start_time_warning_shown = False
        
        time_input_str = self.time_input.get().strip()
        if not time_input_str:
            return
        
        try:
            result = self.calculator.calculate(time_input_str, self.selected_note_type)
            self.current_calculation_result = result
            
            # Show result
            self._show_result(result)
            
            # Process warnings
            self._process_warnings(result)
            
        except CalculationError as e:
            self.error_message.set(str(e))
            self._clear_details()
    
    def _show_result(self, result: CalculationResult):
        """Display the calculation result"""
        result_str = (
            f"{result.start_time.formatted_string()}-"
            f"{result.end_time.formatted_string()}, {result.calls} calls"
        )
        self.result_text.set(result_str)
        
        # Copy to clipboard
        self._copy_to_clipboard(result_str)
        
        # Show details
        self._show_details(result)
    
    def _show_details(self, result: CalculationResult):
        """Show calculation details and billing table"""
        self.details_text.config(state=tk.NORMAL)
        self.details_text.delete(1.0, tk.END)
        
        # Calculation details
        details = "Calculation Details:\n"
        details += f"Duration: {result.duration} minutes\n"
        details += (
            f"Time Range: {result.start_time.formatted_string()} - "
            f"{result.end_time.formatted_string()}\n"
        )
        if result.matched_tier:
            details += f"Matched Tier: {result.matched_tier.description()}\n"
        details += "\n"
        
        # Suggested time range (if available)
        if self.suggested_time_range.get():
            details += f"Suggested Time Range: {self.suggested_time_range.get()}\n\n"
        
        # Billing table
        details += f"Billing Table ({result.note_type.value}):\n"
        details += "-" * 60 + "\n"
        
        table = BillingCalculator.get_billing_table(result.note_type)
        
        if result.note_type == NoteType.PROGRESS_NOTE:
            details += f"{'With Documentation':<20} {'Face to Face':<20} {'Calls':<10}\n"
            details += "-" * 60 + "\n"
            for tier in table:
                matched = result.matched_tier and result.matched_tier.calls == tier.calls
                marker = ">>> " if matched else "    "
                details += (
                    f"{marker}{str(tier.max_minutes or 0):<20} "
                    f"{str(tier.actual_minutes or 0):<20} "
                    f"{str(tier.calls):<10}\n"
                )
        else:  # CONSULT
            details += f"{'Min Minutes':<20} {'Max Minutes':<20} {'Calls':<10}\n"
            details += "-" * 60 + "\n"
            for tier in table:
                matched = result.matched_tier and result.matched_tier.calls == tier.calls
                marker = ">>> " if matched else "    "
                details += (
                    f"{marker}{str(tier.min_minutes or 0):<20} "
                    f"{str(tier.max_minutes or 0):<20} "
                    f"{str(tier.calls):<10}\n"
                )
        
        self.details_text.insert(1.0, details)
        self.details_text.config(state=tk.DISABLED)
    
    def _clear_details(self):
        """Clear the details text area"""
        self.details_text.config(state=tk.NORMAL)
        self.details_text.delete(1.0, tk.END)
        self.details_text.config(state=tk.DISABLED)
    
    def _process_warnings(self, result: CalculationResult):
        """Process and display warnings"""
        warnings = result.warnings
        
        # Find start time warning (only show if not already shown)
        if not self.start_time_warning_shown:
            start_time_warning = next(
                (w for w in warnings if isinstance(w, Warning.StartTimeNotOnHourOrHalfHour)),
                None
            )
            if start_time_warning:
                self.start_time_warning_shown = True
                self._show_start_time_warning(start_time_warning, result)
                return
        
        # Find near tier warning
        near_tier_warning = next(
            (w for w in warnings if isinstance(w, Warning.NearNextTier)),
            None
        )
        if near_tier_warning:
            self._show_near_tier_warning(near_tier_warning, result)
    
    def _show_start_time_warning(
        self, warning: Warning.StartTimeNotOnHourOrHalfHour, result: CalculationResult
    ):
        """Show start time alignment warning"""
        suggested_range = (
            f"{warning.suggested_start_time}-{result.end_time.formatted_string()}"
        )
        self.suggested_time_range.set(suggested_range)
        
        message = (
            f"Start time should be on the hour (e.g., 09:00) or half-hour (e.g., 09:30).\n\n"
            f"Suggested start time: {warning.suggested_start_time}"
        )
        
        response = messagebox.askyesno(
            "Start Time Not Aligned",
            message,
            icon="warning"
        )
        
        if response:
            self._amend_start_time(warning.suggested_start_time, result)
        else:
            self.suggested_time_range.set("")
            self._check_for_near_tier_warning(result)
    
    def _show_near_tier_warning(
        self, warning: Warning.NearNextTier, result: CalculationResult
    ):
        """Show near next tier warning"""
        suggested_range = (
            f"{result.start_time.formatted_string()}-{warning.suggested_end_time}"
        )
        self.suggested_time_range.set(suggested_range)
        
        minutes_text = "minute" if warning.minutes_to_next == 1 else "minutes"
        message = (
            f"You're only {warning.minutes_to_next} {minutes_text} away from "
            f"the next tier ({warning.next_calls} calls).\n\n"
            f"Current: {warning.current_calls} calls\n"
            f"Suggested end time: {warning.suggested_end_time}"
        )
        
        response = messagebox.askyesno("Near Next Tier", message, icon="info")
        
        if response:
            self._amend_time_for_next_tier(warning.suggested_end_time, result)
        else:
            self.suggested_time_range.set("")
    
    def _check_for_near_tier_warning(self, result: CalculationResult):
        """Check for near tier warning after declining start time amendment"""
        near_tier_warning = next(
            (w for w in result.warnings if isinstance(w, Warning.NearNextTier)),
            None
        )
        if near_tier_warning:
            self._show_near_tier_warning(near_tier_warning, result)
    
    def _amend_start_time(self, suggested_start_time: str, result: CalculationResult):
        """Amend the start time based on suggestion"""
        amended_range = f"{suggested_start_time}-{result.end_time.formatted_string()}"
        self.time_input.set(amended_range)
        self._copy_to_clipboard(amended_range)
        self.suggested_time_range.set(amended_range)
        
        # Recalculate
        self.root.after(100, self._calculate_calls)
    
    def _amend_time_for_next_tier(
        self, suggested_end_time: str, result: CalculationResult
    ):
        """Amend the time range to reach next tier"""
        amended_range = f"{result.start_time.formatted_string()}-{suggested_end_time}"
        self.time_input.set(amended_range)
        self._copy_to_clipboard(amended_range)
        self.suggested_time_range.set(amended_range)
        
        # Recalculate
        self.root.after(100, self._calculate_calls)
    
    def _toggle_timer(self):
        """Toggle timer on/off"""
        if self.is_timer_running:
            # Stop timer
            if self.timer_start_time:
                end_time = datetime.now()
                start_str = self.timer_start_time.strftime("%H:%M")
                end_str = end_time.strftime("%H:%M")
                self.time_input.set(f"{start_str}-{end_str}")
            
            self.is_timer_running = False
            self.timer_start_time = None
            self.timer_button.config(text="Start Timer")
            self.timer_label.config(text="")
            
            # Automatically calculate
            self._calculate_calls()
        else:
            # Start timer
            self.timer_start_time = datetime.now()
            self.is_timer_running = True
            self.timer_button.config(text="Stop Timer")
            
            # Clear previous results
            self.error_message.set("")
            self.result_text.set("")
            self.current_calculation_result = None
            self.suggested_time_range.set("")
            self.start_time_warning_shown = False
            self._clear_details()
            
            # Start timer update thread
            self._update_timer_display()
    
    def _update_timer_display(self):
        """Update the timer display"""
        if self.is_timer_running and self.timer_start_time:
            elapsed = datetime.now() - self.timer_start_time
            hours, remainder = divmod(elapsed.seconds, 3600)
            minutes, seconds = divmod(remainder, 60)
            timer_text = f"Timer: {hours:02d}:{minutes:02d}:{seconds:02d}"
            self.timer_label.config(text=timer_text)
            self.root.after(1000, self._update_timer_display)
    
    def _copy_full_result(self):
        """Copy full result to clipboard"""
        if self.result_text.get():
            self._copy_to_clipboard(self.result_text.get())
    
    def _copy_result_number(self):
        """Copy just the number of calls to clipboard"""
        if self.current_calculation_result:
            self._copy_to_clipboard(str(self.current_calculation_result.calls))
    
    def _copy_to_clipboard(self, text: str):
        """Copy text to clipboard"""
        try:
            pyperclip.copy(text)
        except Exception:
            # Fallback if pyperclip fails
            self.root.clipboard_clear()
            self.root.clipboard_append(text)
    
    def _clear_previous_results(self):
        """Clear all previous calculation results"""
        self.result_text.set("")
        self.error_message.set("")
        self.current_calculation_result = None
        self.suggested_time_range.set("")
        self.start_time_warning_shown = False
        self._clear_details()


def main():
    """Main entry point"""
    root = tk.Tk()
    app = BillingTimeCalcApp(root)
    root.mainloop()


if __name__ == "__main__":
    main()
