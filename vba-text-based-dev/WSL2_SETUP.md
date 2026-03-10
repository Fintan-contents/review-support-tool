# WSL2環境での開発（アディショナル）

WSL2 環境を活用することで、より効率的な VBA 開発が可能です。

## なぜWSL2を使うのか

通常の Windows 環境での開発で十分ですが、以下のような場合に WSL2 環境が便利です：

- **Claude Code**: WSL2 上で Claude Code を使用したい
- **Linuxコマンド**: sed、grep、find 等の Linux ツールを活用したい
- **Makefile**: ビルド自動化に Makefile を使用したい
- **開発効率**: Linux シェルでの開発フローに慣れている

## 前提条件

### WSL2環境

- Python 3.10 以上
- 必要なライブラリ（`requirements-wsl2.txt`）：

  ```bash
  pip install -r vba-text-based-dev/requirements-wsl2.txt
  ```

### Windows環境

**なぜWindows環境が必要か**:

VBA のビルド処理には **Excel COM オブジェクト** へのアクセスが必要です。COM は Windows 専用の技術のため、ビルド処理は Windows 環境でのみ実行可能です。

一方、VBA 抽出は純粋なバイナリ解析のため、Windows/Linux/macOS のどの環境でも実行できます。

**必要なパッケージ**:

VBA ビルドには Windows 環境の **pywin32** が必要です。

```cmd
REM Windowsコマンドプロンプトまたは PowerShell で実行
pip install -r vba-text-based-dev\requirements-windows.txt
```

インストール確認：

```cmd
python -c "import win32com.client; print('OK')"
```

**注意**: WSL2 から Windows 側の Python を呼び出すため、`python.exe` が `PATH` に含まれている必要があります。

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

WSL2 と Windows 環境の両方が正しく設定されているか確認します：

```bash
cd /path/to/vba-text-based-dev
make check
```

### 1. プロジェクトの設定ファイルを作成

プロジェクトディレクトリに `wsl2-config.mk` を作成します：

```makefile
# VBA Text-Based Dev Configuration

# プロジェクトディレクトリ
PROJECT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

# xlsmファイルのパス
XLSM_FILE := $(PROJECT_DIR)/path/to/tool.xlsm

# VBA出力ディレクトリ
VBA_OUTPUT_DIR := $(PROJECT_DIR)/vba_modules
```

`$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))` は設定ファイルが配置されているディレクトリのパスです。

### 2. VBA抽出

xlsm ファイルから VBA コードをテキストファイルに抽出します：

**シェルスクリプトを使用（推奨）**:

```bash
cd /path/to/vba-text-based-dev/scripts/wsl2
./extract.sh ../../../doctool/wsl2-config.mk
```

または、Python スクリプトを直接実行：

```bash
python3 scripts/extract_vba.py /path/to/tool.xlsm /path/to/vba_modules
```

### 3. VBA編集

```bash
# 任意のエディタで編集
code ../../../doctool/vba_modules/Sheet1.cls
vim ../../../doctool/vba_modules/Module1.bas
```

### 4. VBAビルド

編集したテキストファイルを xlsm ファイルにマージします：

**シェルスクリプトを使用（推奨）**:

```bash
cd /path/to/vba-text-based-dev/scripts/wsl2
./build.sh ../../../doctool/wsl2-config.mk
```

または、Python スクリプトを直接実行：

```bash
python.exe scripts/build_vba.py /path/to/vba_modules /path/to/tool.xlsm
```

### 5. テスト実行

Windows エクスプローラーから開きます：

1. アドレスバーに以下の形式でパスを入力：

   ```text
   \\wsl.localhost\<ディストリビューション名>\<WSL2上のパス>\review-support-tool\doctool\Excel設計書レビュー指摘事項抽出ツール
   ```

   例：

   ```text
   \\wsl.localhost\Ubuntu\home\username\work\review-support-tool\doctool\Excel設計書レビュー指摘事項抽出ツール
   ```

2. `Excel設計書レビュー指摘事項抽出ツール.xlsm` をダブルクリック

または、Excel から直接開く：

1. Excel を起動
2. `ファイル` → `開く` → `参照`
3. アドレスバーに上記の形式でパスを入力してファイルを選択

### 6. Git管理

```bash
git add ../../../doctool/vba_modules/
git commit -m "feat: Update VBA code"
```

## シェルスクリプトとMakefile

### シェルスクリプト（推奨）

Windows 環境のバッチファイルと同じように、設定ファイルのパスを指定するだけで使えます：

```bash
cd /path/to/vba-text-based-dev/scripts/wsl2
./extract.sh ../../../doctool/wsl2-config.mk    # VBA抽出
./build.sh ../../../doctool/wsl2-config.mk      # VBAビルド
```

### Makefile

より詳細な制御が必要な場合は Makefile を直接使用できます：

- `make check`: 環境チェック（WSL2 と Windows 環境）
- `make CONFIG=path/to/wsl2-config.mk extract`: VBA 抽出（WSL2 で実行）
- `make CONFIG=path/to/wsl2-config.mk build`: VBA ビルド（Windows 側 Python で実行）
- `make clean`: 一時ファイルを削除
- `make help`: ヘルプを表示

**重要**: `extract` と `build` には必ず `CONFIG` 変数で設定ファイルを指定してください。設定ファイルの作成方法は「1. プロジェクトの設定ファイルを作成」を参照してください。

## トラブルシューティング

### CONFIG変数が指定されていない

**エラー**: `❌ エラー: CONFIG変数が指定されていません`

**解決策**:

CONFIG 変数で設定ファイルのパスを必ず指定してください：

```bash
make CONFIG=../doctool/wsl2-config.mk extract
```

### python.exeが見つからない

**エラー**: `python.exe: command not found` または `MZ: command not found`

**原因**: WSL2 の binfmt_misc 設定が欠落している

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

正常に表示されれば OK です。

### pywin32がインストールされていない

**エラー**: `ModuleNotFoundError: No module named 'win32com'`

**解決策**:

```cmd
REM Windowsコマンドプロンプトで実行（WSL2ではなく）
pip install -r vba-text-based-dev\requirements-windows.txt
```

**注意**: pywin32 は **Windows環境に** インストールする必要があります。WSL2 側にインストールしても動作しません。

### Excelが既に開いている

**エラー**: `'NoneType' object has no attribute 'VBProject'`

**解決策**:

1. Excel をすべて閉じる
2. Windows タスクマネージャーで `EXCEL.EXE` プロセスを確認・終了
3. 再度ビルドを実行

## 補足

### WSL2からWindows側のPythonを呼び出す仕組み

WSL2 では `python.exe` コマンドで Windows 側の Python を直接呼び出せます。これにより、WSL2 上で Linux ツール（oletools）を使いながら、Windows 専用の pywin32 も活用できます。

スクリプトの技術的な詳細は [scripts/README.md](./scripts/README.md) を参照してください。
