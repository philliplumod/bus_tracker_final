@echo off
echo ===============================================
echo Bus Tracker - Assignment Error Diagnostic Tool
echo ===============================================
echo.

echo Step 1: Checking ADB connection...
echo -----------------------------------------------
adb devices
if %errorlevel% neq 0 (
    echo ERROR: ADB not found or not in PATH
    echo Please install Android SDK Platform Tools
    pause
    exit /b 1
)
echo.

echo Step 2: Setting up port forwarding...
echo -----------------------------------------------
adb reverse tcp:3000 tcp:3000
if %errorlevel% neq 0 (
    echo ERROR: Failed to set up port forwarding
    echo Make sure device is connected via USB
    pause
    exit /b 1
)
echo SUCCESS: Port forwarding set up (tcp:3000 -^> tcp:3000)
echo.

echo Step 3: Verifying port forwarding...
echo -----------------------------------------------
adb reverse --list
echo.

echo Step 4: Testing backend server...
echo -----------------------------------------------
curl -s http://localhost:3000/api/health
if %errorlevel% neq 0 (
    echo.
    echo WARNING: Backend server may not be running
    echo Please start your backend server:
    echo   cd path\to\backend
    echo   npm start
) else (
    echo.
    echo SUCCESS: Backend server is responding
)
echo.

echo Step 5: Checking Flutter logs...
echo -----------------------------------------------
echo Run this command in a separate terminal to see live logs:
echo   flutter logs
echo.
echo Or to see recent logs:
echo   adb logcat -s flutter:V
echo.

echo ===============================================
echo Diagnostic Complete
echo ===============================================
echo.
echo Next steps:
echo 1. Keep this terminal open (port forwarding is active)
echo 2. Launch the app
echo 3. Login as a rider
echo 4. Check the console output for detailed debug logs
echo.
echo Look for these messages:
echo   - ✅ Auth token present
echo   - 📊 Fetched X total assignments
echo   - ✅ MATCH FOUND!
echo.
echo If you see "❌ NO MATCH FOUND", check:
echo   - User ID matches between login and database
echo   - Assignment exists in your database
echo   - Backend is returning all assignments correctly
echo.
pause
