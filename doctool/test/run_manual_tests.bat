@echo off
REM Excel VBA Manual Test Runner
REM Usage:
REM   run_manual_tests.bat                           - Run all manual scenarios
REM   run_manual_tests.bat scenario05                - Run specific scenario
REM   run_manual_tests.bat scenario05 scenario06     - Run multiple scenarios
REM
REM Actual output files are saved to: test\temp_dir\scenarioXX\

cd /d %~dp0

if "%1"=="" (
    echo ====================================
    echo Running all manual scenarios...
    echo ====================================
) else (
    echo ====================================
    echo Running scenarios: %*
    echo ====================================
)

python scripts\manual_test_runner.py %*

echo.
echo ====================================
echo Manual test completed
echo Actual files saved to: temp_dir\
echo ====================================
pause
