@echo off
REM Excel VBA Test Runner（自動テスト → 手動テストをまとめて実行）
REM Usage:
REM   run_tests.bat                           - Run all tests (auto + manual)
REM   run_tests.bat scenario07                - Run specific scenario
REM   run_tests.bat scenario07 scenario08     - Run multiple scenarios
REM
REM Actual output files are saved to: test\temp_dir\scenarioXX\

cd /d %~dp0
set TOOL_TEST_ROOT=%~dp0

set FRAMEWORK=..\..\..\test-framework\scripts

set PYTHONPATH=%~dp0..\..\..\test-framework\scripts;%PYTHONPATH%

if "%1"=="" (
    echo ====================================
    echo Running all tests ^(auto + manual^)...
    echo ====================================
) else (
    echo ====================================
    echo Running scenarios: %*
    echo ====================================
)

python %FRAMEWORK%\test_runner.py %*

echo.
echo ====================================
echo All tests completed
echo Actual files saved to: temp_dir\
echo ====================================
pause
