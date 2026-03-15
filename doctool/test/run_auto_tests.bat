@echo off
REM Excel VBA Auto Test Runner
REM Usage:
REM   run_auto_tests.bat                                       - Run all auto scenarios
REM   run_auto_tests.bat scenario04                            - Run specific scenario
REM   run_auto_tests.bat scenario07 scenario08                 - Run multiple scenarios
REM   run_auto_tests.bat --include-heavy                       - Run all (including heavy scenarios)
REM   run_auto_tests.bat --include-heavy scenario04            - Run specific scenario (including heavy)
REM   run_auto_tests.bat scenario07 scenario08 --include-heavy - Run multiple (including heavy)
REM
REM Actual output files are saved to: test\temp_dir\scenarioXX\

cd /d %~dp0
set TOOL_TEST_ROOT=%~dp0

set FRAMEWORK=..\..\vba-text-based-dev\test-framework\scripts

set HEAVY_FLAG=
set SCENARIO_COUNT=0
set SCENARIO_FIRST=
set FILTER=

:parse_args
if "%~1"=="" goto dispatch
if "%~1"=="--include-heavy" (
    set HEAVY_FLAG=--include-heavy
    shift
    goto parse_args
)
set /a SCENARIO_COUNT+=1
if %SCENARIO_COUNT%==1 (
    set "SCENARIO_FIRST=%~1"
    set "FILTER=%~1"
) else (
    set "FILTER=%FILTER% or %~1"
)
shift
goto parse_args

:dispatch
if %SCENARIO_COUNT%==0 goto run_all
if %SCENARIO_COUNT%==1 goto run_single
goto run_multi

:run_all
echo ====================================
echo Running all auto scenarios...
echo ====================================
python -m pytest %FRAMEWORK%\auto_test_runner.py -v --tb=short -s %HEAVY_FLAG%
goto end

:run_single
echo ====================================
echo Running scenario: %SCENARIO_FIRST%
echo ====================================
python -m pytest %FRAMEWORK%\auto_test_runner.py::TestScenarioGoldMaster::test_scenario_gold_master[%SCENARIO_FIRST%] -v --tb=short %HEAVY_FLAG%
goto end

:run_multi
echo ====================================
echo Running scenarios: %FILTER%
echo ====================================
python -m pytest %FRAMEWORK%\auto_test_runner.py -v --tb=short -s -k "%FILTER%" %HEAVY_FLAG%

:end
echo.
echo ====================================
echo Auto test completed
echo Actual files saved to: temp_dir\
echo ====================================
pause
