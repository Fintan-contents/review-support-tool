@echo off
REM VBA抽出スクリプト
REM xlsmファイルからVBAコードをテキストファイルに抽出します

echo ======================================================================
echo VBA 抽出
echo ======================================================================
echo.

python "%~dp0extract_vba.py"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ 抽出が完了しました
) else (
    echo.
    echo ❌ 抽出に失敗しました
)

pause
