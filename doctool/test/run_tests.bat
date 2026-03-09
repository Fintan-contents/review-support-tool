@echo off
REM Excel VBA Test Runner
REM Usage:
REM   run_tests.bat           - Run all scenarios
REM   run_tests.bat scenario04 - Run specific scenario

cd /d %~dp0

if "%1"=="" (
    echo ====================================
    echo Running all scenarios...
    echo ====================================
    python -m pytest scripts\test_runner.py -v --tb=short
) else (
    echo ====================================
    echo Running scenario: %1
    echo ====================================
    python -m pytest scripts\test_runner.py::TestScenarioGoldMaster::test_scenario_gold_master[%1] -v --tb=short
)

echo.
echo ====================================
echo Test execution completed
echo ====================================
pause
