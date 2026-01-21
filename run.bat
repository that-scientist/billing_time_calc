@echo off
REM Billing Time Calculator - Windows Launcher
REM This batch file runs the Python application

echo Starting Billing Time Calculator...
echo.

REM Check if Python is available
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python is not installed or not in PATH.
    echo Please install Python from https://www.python.org/downloads/
    echo Make sure to check "Add Python to PATH" during installation.
    pause
    exit /b 1
)

REM Check if requirements are installed
python -c "import pyperclip" >nul 2>&1
if errorlevel 1 (
    echo Installing required dependencies...
    pip install -r requirements.txt
    if errorlevel 1 (
        echo ERROR: Failed to install dependencies.
        pause
        exit /b 1
    )
)

REM Run the application
python main.py

if errorlevel 1 (
    echo.
    echo ERROR: Application failed to start.
    pause
    exit /b 1
)
