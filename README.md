# Billing Time Calculator

A macOS GUI application that calculates billing calls based on time ranges.  This grew out of hectic work days when there wasn't always time to complete documentation right away, so I would at times have to finish up that part of the work at end of day.  This simplifies the process as intended by the billing policies in my provence by billing for the face to face time plus the allowed time for all other matters.  This way the billing gets done reliably in the moment, obviating a dual-reminder system (billing then documentation) I'd been running previously.

## Features

- Input time ranges in `HH:MM-HH:MM` format (24-hour time)
- Automatically calculates duration and determines the number of calls
- Uses a lookup table to map duration to calls based on actual billing minutes

## Lookup Table

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

## Setup

### Using Xcode (Required for macOS GUI)

1. Open Xcode
2. Select "File" → "New" → "Project"
3. Choose "macOS" → "App"
4. Fill in:
   - Product Name: `BillingTimeCalc`
   - Interface: `SwiftUI`
   - Language: `Swift`
   - Click "Next" and choose a location
5. Replace the generated files with the provided Swift files:
   - Delete the default `App.swift` and `ContentView.swift`
   - Add `BillingTimeCalcApp.swift`, `ContentView.swift`, and `BillingCalculator.swift` to your project
6. Build and run (⌘R)

## Distribution

### Creating a Portable Package

To create a distributable package (ZIP and DMG files):

```bash
./package.sh
```

This will create:
- `BillingTimeCalc.zip` - A ZIP archive containing the app and README
- `BillingTimeCalc.dmg` - A DMG disk image for easy installation
- `package/` directory - Contains the app bundle and README

**To distribute:**
1. Share the ZIP file or DMG file
2. Users can extract the ZIP or mount the DMG
3. Drag `BillingTimeCalc.app` to the Applications folder
4. Or double-click the app to run it directly

**System Requirements:**
- macOS 13.0 or later
- No additional dependencies required (uses system frameworks only)

## Building

### Automated Build Scripts

Two build scripts are provided for automated compilation:

#### `build.sh` - Build Only
Builds the project in Release configuration:
```bash
./build.sh
```

To automatically increment the build number:
```bash
./build.sh --increment
```

#### `build_and_run.sh` - Build and Run
Builds the project in Debug configuration and optionally launches it:
```bash
./build_and_run.sh
```

**Note:** These scripts require an Xcode project (`.xcodeproj`) file. If you haven't created one yet, follow the Setup instructions above.

### Version Management

The project includes a version management system to ensure builds replace prior versions properly.

#### Version Script (`version.sh`)

Manage version and build numbers:

```bash
# Get current version
./version.sh get-version

# Get current build number
./version.sh get-build

# Increment build number (automatically updates project.yml)
./version.sh increment-build

# Set version number (e.g., 1.1)
./version.sh set-version 1.1

# Update project.yml with current version/build
./version.sh update
```

The version information is stored in `.version` and automatically synced to `project.yml` and the built app's `Info.plist`. Each build will have a unique build number, ensuring macOS properly replaces previous versions.

### Manual Build

Alternatively, you can build directly using `xcodebuild`:
```bash
xcodebuild -project BillingTimeCalc.xcodeproj -scheme BillingTimeCalc -configuration Release
```

Or build and run from Xcode:
- Open `BillingTimeCalc.xcodeproj` in Xcode
- Press ⌘R to build and run

## Usage

1. Enter a time range in the format `HH:MM-HH:MM` (e.g., `09:00-10:30`)
2. Click "Calculate Calls" or press Enter
3. The app will display the number of calls based on the duration
4. If warnings appear (near next tier or start time alignment), you can choose to amend your times

## Example

- Input: `09:00-09:45` (45 minutes) → Output: `4 calls`
- Input: `14:30-15:30` (60 minutes) → Output: `5 calls`
- Input: `10:00-11:15` (75 minutes) → Output: `6 calls`

