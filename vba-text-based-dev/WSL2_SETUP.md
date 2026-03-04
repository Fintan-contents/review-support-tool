# WSL2環境での開発（アディショナル）

WSL2環境を活用することで、より効率的なVBA開発が可能です。

## なぜWSL2を使うのか

通常のWindows環境での開発で十分ですが、以下のような場合にWSL2環境が便利です：

- **Claude Code**: WSL2上でClaude Codeを使用したい
- **Linuxコマンド**: sed、grep、find等のLinuxツールを活用したい
- **Makefile**: ビルド自動化にMakefileを使用したい
- **開発効率**: Linuxシェルでの開発フローに慣れている

## 前提条件

### WSL2環境

- Python 3.x
- 必要なライブラリ：

  ```bash
  pip install oletools
  ```

### Windows環境

**なぜWindows環境が必要か**:

VBAのビルド処理には **Excel COM オブジェクト** へのアクセスが必要です。COMはWindows専用の技術のため、ビルド処理はWindows環境でのみ実行可能です。

一方、VBA抽出は純粋なバイナリ解析のため、Windows/Linux/macOSのどの環境でも実行できます。

**必要なパッケージ**:

VBAビルドにはWindows環境の **pywin32** が必要です。

```cmd
REM Windowsコマンドプロンプトまたは PowerShell で実行
pip install pywin32
```

インストール確認：

```cmd
python -c "import win32com.client; print('OK')"
```

**注意**: WSL2からWindows側のPythonを呼び出すため、`python.exe`が`PATH`に含まれている必要があります。

## 環境構成

```text
┌─────────────────────────────────────┐
│ WSL2環境                            │
│  - VBA抽出（oletools）              │
│  - VBA編集（任意のエディタ）        │
│  - Makefile（ビルド自動化）         │
└───────────────┬─────────────────────┘
                │
                │ python.exe 経由
                ▼
┌─────────────────────────────────────┐
│ Windows環境                         │
│  - VBAビルド（pywin32）             │
│    ※Excel COMオブジェクトに依存    │
└─────────────────────────────────────┘
```

## 使い方

### 環境チェック

WSL2とWindows環境の両方が正しく設定されているか確認します：

```bash
cd /path/to/vba-text-based-dev
make check
```

### 1. プロジェクトの設定ファイルを作成

プロジェクトディレクトリに`config.mk`を作成します：

```makefile
# VBA Text-Based Dev Configuration

# プロジェクトディレクトリ
PROJECT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

# xlsmファイルのパス
XLSM_FILE := $(PROJECT_DIR)/path/to/tool.xlsm

# VBA出力ディレクトリ
VBA_OUTPUT_DIR := $(PROJECT_DIR)/vba_modules
```

`$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))`は設定ファイルが配置されているディレクトリのパスです。

### 2. VBA抽出

xlsmファイルからVBAコードをテキストファイルに抽出します：

**doctoolの場合**:
```bash
cd /path/to/vba-text-based-dev
make CONFIG=../doctool/config.mk extract
```

**prtoolの場合**:
```bash
cd /path/to/vba-text-based-dev
make CONFIG=../prtool/config.mk extract
```

または、Pythonスクリプトを直接実行：

```bash
python3 scripts/extract_vba.py /path/to/tool.xlsm /path/to/vba_modules
```

### 3. VBA編集

```bash
# 任意のエディタで編集
code ../doctool/vba_modules/Sheet1.cls
vim ../doctool/vba_modules/Module1.bas
```

### 4. VBAビルド

編集したテキストファイルをxlsmファイルにマージします：

**doctoolの場合**:
```bash
cd /path/to/vba-text-based-dev
make CONFIG=../doctool/config.mk build
```

**prtoolの場合**:
```bash
cd /path/to/vba-text-based-dev
make CONFIG=../prtool/config.mk build
```

または、Pythonスクリプトを直接実行：

```bash
python.exe scripts/build_vba.py /path/to/vba_modules /path/to/tool.xlsm
```

### 5. テスト実行

Windowsエクスプローラーから開きます：

1. アドレスバーに以下の形式でパスを入力：

   ```text
   \\wsl.localhost\<ディストリビューション名>\<WSL2上のパス>\review-support-tool\doctool\Excel設計書レビュー指摘事項抽出ツール
   ```

   例：

   ```text
   \\wsl.localhost\Ubuntu\home\username\work\review-support-tool\doctool\Excel設計書レビュー指摘事項抽出ツール
   ```

2. `Excel設計書レビュー指摘事項抽出ツール.xlsm` をダブルクリック

または、Excelから直接開く：

1. Excelを起動
2. `ファイル` → `開く` → `参照`
3. アドレスバーに上記の形式でパスを入力してファイルを選択

### 6. Git管理

```bash
git add ../doctool/vba_modules/
git commit -m "feat: Update VBA code"
```

## Makefile

以下のターゲットが利用可能です：

- `make check`: 環境チェック（WSL2とWindows環境）
- `make CONFIG=path/to/config.mk extract`: VBA抽出（WSL2で実行）
- `make CONFIG=path/to/config.mk build`: VBAビルド（Windows側Pythonで実行）
- `make clean`: 一時ファイルを削除
- `make help`: ヘルプを表示

**重要**: `extract`と`build`には必ず`CONFIG`変数で設定ファイルを指定してください。設定ファイルの作成方法は「1. プロジェクトの設定ファイルを作成」を参照してください。

## トラブルシューティング

### CONFIG変数が指定されていない

**エラー**: `❌ エラー: CONFIG変数が指定されていません`

**解決策**:

CONFIG変数で設定ファイルのパスを必ず指定してください：

```bash
make CONFIG=../doctool/config.mk extract
```

### python.exeが見つからない

**エラー**: `python.exe: command not found` または `MZ: command not found`

**原因**: WSL2のbinfmt_misc設定が欠落している

**解決策**:

```cmd
REM Windowsコマンドプロンプトで実行
wsl --shutdown
REM 数秒待ってから、再度WSLを起動
```

### python.exeが動作するか確認

```bash
python.exe --version
```

正常に表示されればOKです。

### pywin32がインストールされていない

**エラー**: `ModuleNotFoundError: No module named 'win32com'`

**解決策**:

```cmd
REM Windowsコマンドプロンプトで実行（WSL2ではなく）
pip install pywin32
```

**注意**: pywin32は **Windows環境に** インストールする必要があります。WSL2側にインストールしても動作しません。

### Excelが既に開いている

**エラー**: `'NoneType' object has no attribute 'VBProject'`

**解決策**:

1. Excelをすべて閉じる
2. Windowsタスクマネージャーで `EXCEL.EXE` プロセスを確認・終了
3. 再度ビルドを実行

## 補足

### WSL2からWindows側のPythonを呼び出す仕組み

WSL2では `python.exe` コマンドでWindows側のPythonを直接呼び出せます。これにより、WSL2上でLinuxツール（oletools）を使いながら、Windows専用のpywin32も活用できます。

スクリプトの技術的な詳細は [scripts/README.md](./scripts/README.md) を参照してください。
