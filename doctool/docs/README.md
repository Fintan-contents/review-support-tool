# Excel設計書レビュー指摘事項抽出ツール 詳細設計書

**対象ファイル**: `Excel設計書レビュー指摘事項抽出ツール.xlsm`

---

## ドキュメント一覧

| ファイル | 内容 |
|---------|------|
| [01-overview.md](./01-overview.md) | 概要・アーキテクチャ・Excelシート構造 |
| [02-vba-modules.md](./02-vba-modules.md) | VBAモジュール構成・プロシージャ一覧 |
| [03-process-flow.md](./03-process-flow.md) | 主要な処理フロー・詳細処理仕様・データフロー |
| [04-error-handling.md](./04-error-handling.md) | エラーハンドリング・メッセージ一覧 |
| [05-settings.md](./05-settings.md) | 設定項目一覧・定数定義・改版履歴 |

---

## ツールバージョン

| バージョン | 内容 |
|-----------|------|
| 2024-10-25 | GitHub Releases の初期リリース。本ドキュメント群および自動テスト基盤はこのバージョンのマクロをベースにテキスト管理に移行したもの |
| 2026-03-15 | VBAコード品質改善（cmd_289）: `CmdGen_Click_Core` を18の Sub/Function に分割・`BasicSettings`/`MappingConfig` 型定義追加・エラーハンドリング統一（`CleanupOnError`）・シート名定数化（`SHT_*`）・マジックナンバー定数化 |
| 2026-03-31（暫定） | 動的カテゴリ対応（カテゴリ数の可変化・E12/E13 エラー追加）。詳細は [v2-plan.md](./v2-plan.md) を参照 |
