@echo off
echo ================================================
echo Backend API Structure Test
echo ================================================
echo.
echo This script tests if your backend API returns
echo the correct nested/joined data structure.
echo.

set /p TOKEN="Enter your access token (from login): "
echo.

echo Testing: GET /api/user-assignments
echo ------------------------------------------------
curl -s http://localhost:3000/api/user-assignments ^
  -H "Authorization: Bearer %TOKEN%" ^
  -H "Content-Type: application/json" > test_response.json

echo.
echo Response saved to: test_response.json
echo.

echo Checking response structure...
echo.

findstr /C:"\"user\"" test_response.json >nul
if %errorlevel% equ 0 (
    echo [OK] Response contains "user" object
) else (
    echo [FAIL] Response missing "user" object
    echo        Your backend is NOT returning nested user data!
)

findstr /C:"\"bus_route\"" test_response.json >nul
if %errorlevel% equ 0 (
    echo [OK] Response contains "bus_route" object
) else (
    echo [FAIL] Response missing "bus_route" object
    echo        Your backend is NOT joining bus_routes table!
)

findstr /C:"\"route\"" test_response.json >nul
if %errorlevel% equ 0 (
    echo [OK] Response contains "route" object
) else (
    echo [FAIL] Response missing "route" object
    echo        Your backend is NOT joining routes table!
)

findstr /C:"\"bus\"" test_response.json >nul
if %errorlevel% equ 0 (
    echo [OK] Response contains "bus" object
) else (
    echo [FAIL] Response missing "bus" object
    echo        Your backend is NOT joining buses table!
)

findstr /C:"\"starting_terminal\"" test_response.json >nul
if %errorlevel% equ 0 (
    echo [OK] Response contains "starting_terminal" object
) else (
    echo [FAIL] Response missing "starting_terminal" object
    echo        Your backend is NOT joining terminals table!
)

findstr /C:"\"destination_terminal\"" test_response.json >nul
if %errorlevel% equ 0 (
    echo [OK] Response contains "destination_terminal" object
) else (
    echo [FAIL] Response missing "destination_terminal" object
    echo        Your backend is NOT joining terminals table!
)

echo.
echo ================================================
echo Full response:
echo ================================================
type test_response.json
echo.
echo.

echo ================================================
echo DIAGNOSIS:
echo ================================================
echo.
echo If you see [FAIL] messages above, your backend
echo is NOT returning the required nested structure.
echo.
echo ACTION REQUIRED:
echo See BACKEND_API_REQUIREMENTS.md for:
echo - Complete SQL query with all JOINs
echo - Expected JSON response format
echo - Backend implementation examples
echo.
pause
