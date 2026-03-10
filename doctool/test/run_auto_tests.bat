@echo off
REM Excel VBA Auto Test Runner
REM Usage:
REM   run_auto_tests.bat                  - Run all auto scenarios
REM   run_auto_tests.bat scenario04       - Run specific scenario
REM
REM Actual output files are saved to: test\temp_dir\scenarioXX\

cd /d %~dp0

if "%1"=="" (
    echo ====================================
    echo Running all auto scenarios...
    echo ====================================
    python -m pytest scripts\auto_test_runner.py -v --tb=short
) else (
    echo ====================================
    echo Running scenario: %1
    echo ====================================
    python -m pytest scripts\auto_test_runner.py::TestScenarioGoldMaster::test_scenario_gold_master[%1] -v --tb=short
)

echo.
echo ====================================
echo Auto test completed
echo Actual files saved to: temp_dir\
echo ====================================
pause
