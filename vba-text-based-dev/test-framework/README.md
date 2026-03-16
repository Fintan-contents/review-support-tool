# VBA 自動テストフレームワーク

Excel VBA マクロ（xlsm）を対象とした Gold Master テストフレームワーク。
`doctool`、`prtool` など複数のツールで共用できるよう、ツール固有の設定は
各ツールの `test/tool_config.yaml` に分離している。

## 仕組みの概要

### コンポーネント構成

```mermaid
flowchart TB
    subgraph tool["ツール（doctool / prtool 等）"]
        xlsm["📊 *.xlsm\nVBA ツール本体"]
        subgraph tool_test["tool/test/"]
            tool_config["tool_config.yaml\nツール固有設定"]
            subgraph scenarios["auto/scenarioXX/"]
                config_yaml["config.yaml\nテスト設定・観点"]
                fixtures["入力 .xlsx\nフィクスチャ"]
                gold_master["_expected.xlsx\nGold Master\n（期待出力）"]
            end
        end
    end

    subgraph framework["test-framework（汎用・複数ツールで共用）"]
        auto_runner["auto_test_runner.py\npytest アダプタ"]
        scenario_runner["scenario_runner.py\nVBA 実行・結果評価"]
        xlsx_diff["xlsx_diff.py\n差分比較エンジン"]
    end

    bat(["run_auto_tests.bat"])

    bat --> auto_runner
    auto_runner --> scenario_runner
    tool_config -->|ツール設定を読み込み| scenario_runner
    config_yaml -->|テスト設定を読み込み| scenario_runner
    fixtures -->|テスト実行時にコピー| scenario_runner
    scenario_runner <-->|COM 経由で操作| xlsm
    scenario_runner --> xlsx_diff
    xlsx_diff -->|差分比較| gold_master
```

### テスト実行フロー

1回のシナリオ実行で何が起きるかを示します。

```mermaid
flowchart TD
    bat(["run_auto_tests.bat"])
    --> pytest["pytest\nauto_test_runner.py\nシナリオを自動収集"]
    --> runner["scenario_runner.py\nシナリオごとに実行"]

    runner --> copy["フィクスチャを\ntemp_dir/ にコピー"]
    copy --> excel["Excel を起動\nxlsm・入力 xlsx を開く"]
    excel --> setup["config.yaml の setup を適用\n（カテゴリ設定・名前付き範囲・\nActiveX コントロール 等）"]
    setup --> vba["VBA マクロを実行\n（COM 経由・自動モード）"]
    vba --> save["出力ファイルを保存\nExcel を終了"]
    save --> eval["結果を評価"]

    eval --> gm["📊 Gold Master 比較\n_expected.xlsx との全シート差分"]
    eval --> msg["💬 ダイアログログ検証\nexpected_messages 照合"]
    eval --> file["📋 ファイルアサーション\nassert_no_sheets 等"]

    gm & msg & file --> result{{"✅ PASS / ❌ FAIL"}}
```

### テストファースト開発サイクル

```mermaid
flowchart LR
    s1["① シナリオ作成\nconfig.yaml +\n入力フィクスチャ"]
    --> s2["② Gold Master 作成\nVBA 修正後の期待出力を\n_expected.xlsx として保存"]
    --> s3["③ テスト実行\nrun_auto_tests.bat\n→ FAIL を確認（レッド）"]
    --> s4["④ VBA 実装\nvba_modules/ を編集\nbuild_vba.py でビルド"]
    --> s5["⑤ テスト実行\nrun_auto_tests.bat\n→ PASS を確認（グリーン）"]
    --> s6["⑥ コミット\nvba_modules/ + xlsm\n+ Gold Master"]
```

## ディレクトリ構成

```
test-framework/
└── scripts/
    ├── scenario_runner.py     # VBA 実行・結果評価のコアロジック
    ├── auto_test_runner.py    # pytest アダプタ（自動テスト）
    ├── manual_test_runner.py  # 対話型ランナー（手動テスト）
    ├── conftest.py            # pytest 共通設定・セッションログ
    ├── test_runner.py         # 自動＋手動をまとめて実行するオーケストレーター
    └── helpers/
        ├── config_loader.py   # config.yaml の読み込み・バリデーション
        ├── fixture_manager.py # フィクスチャのコピー管理
        ├── tee_logger.py      # stdout をコンソールとファイルに同時出力
        ├── xlsx_diff.py       # xlsx ファイルの差分比較
        └── xlsx_assertions.py # xlsx に対するアサーションヘルパー
```

## ツール側の準備

各ツールの `test/` ディレクトリに以下を用意する。

### `tool_config.yaml`

```yaml
xlsm_path: "../<ツール名>/<ツール名>.xlsm"  # test/ からの相対パス
xlsm_name: "<ツール名>.xlsm"
```

### ディレクトリ構成

```
<tool>/test/
├── tool_config.yaml   # ← ツール固有設定
├── auto/              # 自動テストシナリオ
│   ├── scenario01/
│   │   ├── config.yaml
│   │   ├── <入力>.xlsx
│   │   └── <入力>_expected.xlsx
│   └── ...
├── manual/            # 手動テストシナリオ
│   └── ...
├── temp_dir/          # テスト実行時の作業領域（Git 管理外）
├── run_auto_tests.bat
├── run_manual_tests.bat
└── run_tests.bat
```

### `.bat` ファイルの共通パターン

```bat
cd /d %~dp0
set TOOL_TEST_ROOT=%~dp0
set FRAMEWORK=..\..\vba-text-based-dev\test-framework\scripts
python -m pytest %FRAMEWORK%\auto_test_runner.py -v --tb=short -s
```

## `config.yaml` のキー一覧

| キー | 型 | 説明 |
|------|----|------|
| `viewpoint` | string | テスト観点の説明（ログ表示用） |
| `mode` | string | `"manual"` で手動モード、省略で自動モード |
| `steps` | list | 実行ステップ（必須）|
| `setup` | dict | VBA 実行前の設定（`use_review_record`, `categories` など） |
| `skip_open_files` | list | Python が開かないファイルの正規表現パターン |
| `file_expectations` | list | `assert_no_sheets` などのファイル単位アサーション |
| `excluded_cells` | list | Gold Master 比較から除外するセル参照 |
| `template_assertions` | list | xlsm テンプレートシートへのアサーション |
| `expected_messages` | list | 期待するダイアログメッセージ ID（`[MSG:XX]` 形式） |

### `steps` の `action` 一覧

| action | 説明 |
|--------|------|
| `extract` | 指摘事項抽出マクロを実行（`review_times` 必須） |
| `delete_comments` | コメント一括削除マクロを実行 |
| `delete_sheets` | 結果シート一括削除マクロを実行 |

## 環境変数

| 変数 | 説明 |
|------|------|
| `TOOL_TEST_ROOT` | ツールの `test/` ディレクトリへの絶対パス。`.bat` が自動設定する |
