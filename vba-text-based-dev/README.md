# VBA Text-Based Development Environment

Excel VBAツールをテキストベースで開発するための**汎用的な**環境です。

## 背景・課題

Excel VBAマクロには以下の課題があります：

- **バイナリ形式**: VBAコードはxlsmファイル内にバイナリ形式で埋め込まれる
- **差分が見えない**: Git等のバージョン管理システムで変更内容を追跡できない
- **レビューが困難**: コードレビュー時に差分を確認できないため、品質管理が難しい

## 解決策

この環境では、VBAコードを以下のワークフローで管理します：

1. **VBA抽出**: xlsmファイルからVBAコードをテキストファイルに抽出
2. **テキスト編集**: 通常のテキストエディタでVBAコードを編集
3. **VBAビルド**: 編集したテキストファイルをxlsmファイルにマージ
4. **Git管理**: テキストファイルをGitでバージョン管理（差分・レビューが可能）

## ディレクトリ構造

```text
review-support-tool/
├── vba-text-based-dev/      # VBA開発環境（汎用）
│   ├── README.md
│   ├── scripts/
│   │   ├── extract.bat      # VBA抽出バッチファイル
│   │   ├── extract_vba.py   # VBA抽出スクリプト
│   │   ├── build.bat        # VBAビルドバッチファイル
│   │   └── build_vba.py     # VBAビルドスクリプト
│   └── vba_modules/         # 一時作業ディレクトリ
├── doctool/
│   ├── vba_modules/         # VBAテキストファイル（doctool用）
│   └── Excel設計書レビュー指摘事項抽出ツール/
│       └── *.xlsm
└── prtool/
    ├── vba_modules/         # VBAテキストファイル（prtool用）
    └── プルリクエストコメント抽出ツール/
        └── *.xlsm
```

各プロジェクトに`vba_modules`フォルダを配置し、VBAテキストファイルを管理します。

## 前提条件

- Python 3.x
- 必要なライブラリ：

  ```cmd
  pip install oletools pywin32
  ```

インストール確認：

```cmd
python -c "import oletools; print('oletools OK')"
python -c "import win32com.client; print('pywin32 OK')"
```

## 使い方

### 1. プロジェクトの設定ファイルを作成

プロジェクトディレクトリに`config.bat`を作成します：

```bat
@echo off
REM VBA Text-Based Dev Configuration

REM xlsmファイルのパス
set XLSM_FILE=%~dp0path\to\tool.xlsm

REM VBA出力ディレクトリ
set VBA_OUTPUT_DIR=%~dp0vba_modules
```

`%~dp0`は設定ファイルが配置されているディレクトリのパスです。

### 2. VBA抽出

xlsmファイルからVBAコードをテキストファイルに抽出します：

```cmd
cd vba-text-based-dev\scripts
extract.bat ..\..\doctool\config.bat
```

または、Pythonスクリプトを直接実行：

```cmd
cd vba-text-based-dev
python scripts\extract_vba.py C:\path\to\tool.xlsm C:\path\to\vba_modules
```

**出力**: 指定したVBA出力ディレクトリに各VBAモジュールがテキストファイルとして保存されます。

### 3. VBA編集

VBA出力ディレクトリ配下のテキストファイルを任意のエディタで編集します：

- Visual Studio Code
- Notepad++
- メモ帳
- など

### 4. VBAビルド

編集したテキストファイルをxlsmファイルにマージします：

```cmd
cd vba-text-based-dev\scripts
build.bat ..\..\doctool\config.bat
```

または、Pythonスクリプトを直接実行：

```cmd
cd vba-text-based-dev
python scripts\build_vba.py C:\path\to\vba_modules C:\path\to\tool.xlsm
```

### 5. テスト実行

ビルド後のxlsmファイルをExcelで開いて動作確認します：

1. エクスプローラーでxlsmファイルの場所を開く
2. xlsmファイルをダブルクリック
3. マクロを有効化して動作確認

### 6. Git管理

VBAテキストファイルをコミットします：

```cmd
git add doctool\vba_modules\
git commit -m "feat: Update VBA code"
```

## トラブルシューティング

### 設定ファイルが指定されていない

**エラー**: `❌ エラー: 設定ファイルのパスを指定してください`

**解決策**:

バッチファイルの第1引数に設定ファイルのパスを指定してください：

```cmd
cd vba-text-based-dev\scripts
extract.bat ..\..\doctool\config.bat
```

### oletoolsが見つからない

**エラー**: `ModuleNotFoundError: No module named 'oletools'`

**解決策**:

```cmd
pip install oletools
```

### pywin32が見つからない

**エラー**: `ModuleNotFoundError: No module named 'win32com'`

**解決策**:

```cmd
pip install pywin32
```

### xlsmファイルが壊れた

**症状**: ビルド後にExcelで開くとエラー、またはコンパイルエラー

**解決策**:

Git履歴から復元します：

```cmd
git restore doctool\Excel設計書レビュー指摘事項抽出ツール\Excel設計書レビュー指摘事項抽出ツール.xlsm
```

### Excelが既に開いている

**エラー**: `'NoneType' object has no attribute 'VBProject'`

**解決策**:

1. Excelをすべて閉じる
2. タスクマネージャーで `EXCEL.EXE` プロセスを確認・終了
3. 再度ビルドを実行

## アディショナルな開発環境

WSL2環境でMakefileを活用した開発も可能です。詳細は [WSL2_SETUP.md](./WSL2_SETUP.md) を参照してください。

スクリプトの技術的な詳細は [scripts/README.md](./scripts/README.md) を参照してください。
