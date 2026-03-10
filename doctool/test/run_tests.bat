@echo off
REM Excel VBA Test Runner（自動テスト → 手動テストをまとめて実行）
REM
REM Actual output files are saved to: test\temp_dir\scenarioXX\

cd /d %~dp0

echo ====================================
echo Running all tests (auto + manual)...
echo ====================================
python scripts\test_runner.py

echo.
echo ====================================
echo All tests completed
echo Actual files saved to: temp_dir\
echo ====================================
pause
