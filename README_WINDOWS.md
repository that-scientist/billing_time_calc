# Billing Time Calculator - Windows Version

A Windows GUI application that calculates billing calls based on time ranges for medical notes. This is a Python/Tkinter port of the original macOS SwiftUI application.

## Features

- Input time ranges in `HH:MM-HH:MM` format (24-hour or 12-hour time)
- Support for both Progress Notes and Consult notes
- Automatically calculates duration and determines the number of calls
- Uses lookup tables to map duration to calls based on actual billing minutes
- Timer feature to automatically capture start and end times
- Warnings for near-next-tier and start time alignment
- Displays billing tables with matched tier highlighting
- Automatic clipboard copying of results

## System Requirements

- Windows 7 or later
- Python 3.7 or later
- No additional system dependencies required

## Installation

### Option 1: Using Python (Recommended)

1. **Install Python** (if not already installed):
   - Download Python from [python.org](https://www.python.org/downloads/)
   - During installation, check "Add Python to PATH"

2. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

3. **Run the application**:
   ```bash
   python main.py
   ```
   
   Or double-click `run.bat` (if available)

### Option 2: Create Standalone Executable (Optional)

To create a standalone `.exe` file that doesn't require Python:

1. Install PyInstaller:
   ```bash
   pip install pyinstaller
   ```

2. Create executable:
   ```bash
   pyinstaller --onefile --windowed --name "BillingTimeCalc" main.py
   ```

3. The executable will be in the `dist` folder

## Usage

1. **Select Note Type**: Choose between "Progress Note" or "Consult"
2. **Enter Time Range**: 
   - Type a time range in the format `HH:MM-HH:MM` (e.g., `09:00-10:30`)
   - Or use formats like `09:00 to 10:30` or `9:00 AM to 10:30 AM`
   - Supports both 24-hour and 12-hour formats
3. **Calculate**: Click "Calculate Calls" or press Enter
4. **Use Timer**: Click "Start Timer" to begin timing, then "Stop Timer" to automatically capture the time range
5. **View Results**: The app displays:
   - Number of calls
   - Duration in minutes
   - Matched billing tier
   - Full billing table with highlighted matched tier
6. **Copy Results**: Use "Copy Full" or "Copy Number" buttons to copy results to clipboard

## Lookup Tables

### Progress Note Table

| Max Minutes | Actual Minutes | Calls |
|------------|----------------|-------|
| 30         | 24             | 3     |
| 45         | 36             | 4     |
| 60         | 48             | 5     |
| 75         | 60             | 6     |
| 90         | 72             | 7     |
| 105        | 84             | 8     |
| 120        | 96             | 9     |
| 135        | 108            | 10    |
| 150        | 120            | 11    |
| 165        | 132            | 12    |

### Consult Note Table

| Min Minutes | Max Minutes | Calls |
|------------|------------|-------|
| 61         | 71         | 1     |
| 72         | 86         | 2     |
| 87         | 101        | 3     |
| 102        | 116        | 4     |
| 117        | 131        | 5     |
| 132        | 146        | 6     |
| 147        | 161        | 7     |
| 162        | 176        | 8     |
| 177        | 180        | 9     |

## Examples

- Input: `09:00-09:45` (45 minutes, Progress Note) → Output: `4 calls`
- Input: `14:30-15:30` (60 minutes, Progress Note) → Output: `5 calls`
- Input: `10:00-11:15` (75 minutes, Progress Note) → Output: `6 calls`
- Input: `09:00-10:05` (65 minutes, Consult) → Output: `1 call`
- Input: `9:00 AM to 10:30 AM` (90 minutes, Progress Note) → Output: `7 calls`

## Warnings

The application will show warnings in the following cases:

1. **Near Next Tier**: If you're within 10 minutes of the next billing tier, you'll be prompted to amend the time to reach the next tier
2. **Start Time Alignment**: For Progress Notes, if the start time is not on the hour or half-hour, you'll be suggested to align it

## File Structure

```
billing_time_calc/
├── main.py                 # Main GUI application
├── billing_calculator.py    # Core calculation logic
├── requirements.txt        # Python dependencies
├── README_WINDOWS.md      # This file
└── run.bat                # Windows batch file to run the app
```

## Troubleshooting

### "Python is not recognized"
- Make sure Python is installed and added to PATH
- Try using `py` instead of `python`: `py main.py`

### "Module not found" errors
- Install dependencies: `pip install -r requirements.txt`

### Clipboard not working
- The app uses `pyperclip` for clipboard operations
- If clipboard fails, try installing: `pip install --upgrade pyperclip`

## Differences from macOS Version

- Uses Tkinter instead of SwiftUI for the GUI
- Same calculation logic and features
- Windows-native look and feel
- Timer display shows elapsed time

## License

Same as the original macOS version.
