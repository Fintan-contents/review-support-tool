@echo off
REM Excel VBA Manual Test Runner
REM Usage:
REM   run_manual_tests.bat                  - Run all manual scenarios
REM   run_manual_tests.bat scenario05_no    - Run specific scenario

cd /d %~dp0

if "%1"=="" (
    echo ====================================
    echo Running all manual scenarios...
    echo ====================================
    python scripts\manual_test_runner.py
) else (
    echo ====================================
    echo Running scenario: %1
    echo ====================================
    python scripts\manual_test_runner.py %1
)

echo.
echo ====================================
echo Manual test execution completed
echo ====================================
pause
