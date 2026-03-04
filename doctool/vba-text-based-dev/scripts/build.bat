@echo off
REM VBAビルドスクリプト
REM xlsmファイルにVBAコードをマージします

REM コンソールをUTF-8モードに切り替え
chcp 65001 >nul

echo ======================================================================
echo VBA ビルド
echo ======================================================================
echo.

python "%~dp0build_vba.py"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ ビルドが完了しました
) else (
    echo.
    echo ❌ ビルドに失敗しました
)

pause
