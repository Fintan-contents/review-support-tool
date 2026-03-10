@echo off
REM Excel VBA Auto Test Runner
REM Usage:
REM   run_auto_tests.bat                           - Run all auto scenarios
REM   run_auto_tests.bat scenario04                - Run specific scenario
REM   run_auto_tests.bat scenario07 scenario08     - Run multiple scenarios
REM
REM Actual output files are saved to: test\temp_dir\scenarioXX\

cd /d %~dp0

if "%1"=="" goto run_all
if "%2"=="" goto run_single
goto run_multi

:run_all
echo ====================================
echo Running all auto scenarios...
echo ====================================
python -m pytest scripts\auto_test_runner.py -v --tb=short
goto end

:run_single
echo ====================================
echo Running scenario: %1
echo ====================================
python -m pytest scripts\auto_test_runner.py::TestScenarioGoldMaster::test_scenario_gold_master[%1] -v --tb=short
goto end

:run_multi
set "FILTER=%1"
:build_filter
shift
if "%1"=="" goto run_filtered
set "FILTER=%FILTER% or %1"
goto build_filter

:run_filtered
echo ====================================
echo Running scenarios: %FILTER%
echo ====================================
python -m pytest scripts\auto_test_runner.py -v --tb=short -k "%FILTER%"

:end
echo.
echo ====================================
echo Auto test completed
echo Actual files saved to: temp_dir\
echo ====================================
pause
