@echo off
REM VBA抽出スクリプト
REM xlsmファイルからVBAコードをテキストファイルに抽出します

REM コンソールをUTF-8モードに切り替え
chcp 65001 >nul

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
