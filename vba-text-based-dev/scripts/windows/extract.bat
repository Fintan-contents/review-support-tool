@echo off
REM VBA抽出スクリプト
REM xlsmファイルからVBAコードをテキストファイルに抽出します
REM
REM 使い方: extract.bat [設定ファイルのパス]
REM 例: extract.bat ..\..\..\doctool\win-config.bat

REM コンソールをUTF-8モードに切り替え
chcp 65001 >nul

echo ======================================================================
echo VBA 抽出
echo ======================================================================
echo.

REM 設定ファイルのパスを確認
if "%~1"=="" (
    echo ❌ エラー: 設定ファイルのパスを指定してください
    echo.
    echo 使い方: extract.bat [設定ファイルのパス]
    echo.
    echo 例:
    echo   extract.bat ..\..\..\doctool\win-config.bat
    echo   extract.bat ..\..\..\prtool\win-config.bat
    echo.
    pause
    exit /b 1
)

REM 設定ファイルが存在するか確認
if not exist "%~1" (
    echo ❌ エラー: 設定ファイルが見つかりません: %~1
    echo.
    pause
    exit /b 1
)

REM 設定ファイルを読み込む
call "%~1"

REM 設定ファイルで変数が設定されているか確認
if "%XLSM_FILE%"=="" (
    echo ❌ エラー: 設定ファイルでXLSM_FILEが設定されていません
    echo.
    pause
    exit /b 1
)

if "%VBA_OUTPUT_DIR%"=="" (
    echo ❌ エラー: 設定ファイルでVBA_OUTPUT_DIRが設定されていません
    echo.
    pause
    exit /b 1
)

REM 設定内容を表示
echo 設定ファイル: %~1
echo xlsmファイル: %XLSM_FILE%
echo VBA出力先: %VBA_OUTPUT_DIR%
echo.

REM Python スクリプトを実行
python "%~dp0..\extract_vba.py" "%XLSM_FILE%" "%VBA_OUTPUT_DIR%"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ 抽出が完了しました
) else (
    echo.
    echo ❌ 抽出に失敗しました
)

pause
