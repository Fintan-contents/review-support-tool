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
│   ├── Makefile
│   ├── scripts/
│   │   ├── extract_vba.py   # VBA抽出スクリプト
│   │   └── build_vba.py     # VBAビルドスクリプト
│   └── vba_modules/         # 一時作業ディレクトリ
├── doctool/
│   ├── config.mk            # doctool用の設定
│   ├── vba_modules/         # VBAテキストファイル（doctool用）
│   └── Excel設計書レビュー指摘事項抽出ツール/
│       └── *.xlsm
└── prtool/
    ├── config.mk            # prtool用の設定
    ├── vba_modules/         # VBAテキストファイル（prtool用）
    └── プルリクエストコメント抽出ツール/
        └── *.xlsm
```

**ポイント**: 各プロジェクト（doctool、prtoolなど）に`config.mk`を配置し、xlsmファイルのパスとVBA出力先を指定します。

## 前提条件

- Python 3.x
- 必要なライブラリ：

  ```bash
  # Linux側（VBA抽出用）
  pip3 install oletools

  # Windows側（VBAビルド用）
  pip install pywin32
  ```

インストール確認：

```bash
# Linux側
python3 -c "import oletools; print('oletools OK')"

# Windows側
python -c "import win32com.client; print('pywin32 OK')"
```

## 使い方

### 1. プロジェクトの設定ファイルを作成

プロジェクトディレクトリに`config.mk`を作成します：

```makefile
# config.mk の例

# xlsmファイルのパス（絶対パス推奨）
XLSM_FILE := /path/to/your/project/tool.xlsm

# VBA出力ディレクトリ（絶対パス推奨）
VBA_OUTPUT_DIR := /path/to/your/project/vba_modules
```

### 2. VBA抽出

xlsmファイルからVBAコードをテキストファイルに抽出します：

**WSL2の場合**:
```bash
cd /path/to/vba-text-based-dev
make CONFIG=/path/to/your/project/config.mk extract
```

**Windows CMDの場合**:
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

**WSL2の場合**:
```bash
cd /path/to/vba-text-based-dev
make CONFIG=/path/to/your/project/config.mk build
```

**Windows CMDの場合**:
```cmd
cd vba-text-based-dev
python scripts\build_vba.py C:\path\to\vba_modules C:\path\to\tool.xlsm
```

**注意**: ビルドはWindows環境でのみ実行可能です（Excel COM APIを使用するため）。

### 5. テスト実行

ビルド後のxlsmファイルをExcelで開いて動作確認します：

1. エクスプローラーでxlsmファイルの場所を開く
2. xlsmファイルをダブルクリック
3. マクロを有効化して動作確認

### 6. Git管理

VBAテキストファイルをコミットします：

```bash
git add path/to/vba_modules/
git commit -m "feat: Update VBA code"
```

## 複数プロジェクトでの使用例

### doctool（Excel設計書レビュー指摘事項抽出ツール）

```bash
# VBA抽出
make CONFIG=../doctool/config.mk extract

# VBA編集
code ../doctool/vba_modules/

# VBAビルド
make CONFIG=../doctool/config.mk build
```

### prtool（プルリクエストコメント抽出ツール）

```bash
# VBA抽出
make CONFIG=../prtool/config.mk extract

# VBA編集
code ../prtool/vba_modules/

# VBAビルド
make CONFIG=../prtool/config.mk build
```

## トラブルシューティング

### CONFIG変数が指定されていない

**エラー**: `❌ エラー: CONFIG変数が指定されていません`

**解決策**:

```bash
# CONFIG=path/to/config.mk を必ず指定してください
make CONFIG=../doctool/config.mk extract
```

### oletoolsが見つからない

**エラー**: `ModuleNotFoundError: No module named 'oletools'`

**解決策**:

```bash
pip3 install oletools
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

```bash
git restore path/to/tool.xlsm
```

### Excelが既に開いている

**エラー**: `'NoneType' object has no attribute 'VBProject'`

**解決策**:

1. Excelをすべて閉じる
2. タスクマネージャーで `EXCEL.EXE` プロセスを確認・終了
3. 再度ビルドを実行

## アディショナルな開発環境

WSL2環境でMakefileやLinuxコマンドを活用した、より効率的な開発も可能です。

詳細は [WSL2_SETUP.md](./WSL2_SETUP.md) を参照してください。

スクリプトの技術的な詳細は [scripts/README.md](./scripts/README.md) を参照してください。
