# VBAモジュール構成

---

## モジュール一覧

| モジュール名 | 種類 | 行数 | 説明 |
|------------|------|------|------|
| `Sheet1.cls` | クラスモジュール | 1574行 | **メイン処理**（レビュー指摘事項抽出シート） |
| `Module1.bas` | 標準モジュール | 316行 | **ユーティリティ関数群・共通定数・型定義** |
| `Module2.bas` | 標準モジュール | 139行 | **クリーンアップ処理**（コメント・シート削除・メッセージ表示） |
| `Sheet8.cls` | クラスモジュール | 31行 | 不明（抽出結果で中身なし） |
| `ThisWorkbook.cls` | クラスモジュール | 2行 | 空 |
| `SheetTemplate.cls` | クラスモジュール | 2行 | 空（レビュー結果シートテンプレート） |
| `ErrorSheetTemplate.cls` | クラスモジュール | 2行 | 空（エラーシートテンプレート） |
| `Sheet2.cls`～`Sheet7.cls` | クラスモジュール | 各2行 | 空（各種シートのクラス） |

---

## 主要プロシージャ一覧

### Sheet1.cls（メイン処理）

`CmdGen_Click_Core` は以下の 18 の Sub/Function に分割されており、オーケストレーション関数として各フェーズを順次呼び出す構成になっている。

#### イベントプロシージャ・内部ヘルパー

| プロシージャ名 | 種類 | 説明 |
|--------------|------|------|
| `CmdGen_Click()` | Private Sub | レビュー指摘事項抽出ボタンクリック（UIエントリポイント） |
| `CbAdjustCmntPos_Click()` | Private Sub | コメント位置調整チェックボックス |
| `CheckBox1_Click()` | Private Sub | チェックボックス（用途不明） |
| `CleanupOnError()` | Private Sub | バリデーション失敗・異常終了時の共通クリーンアップ（`Application.ScreenUpdating` / `Application.Cursor` を復元） |

#### メインオーケストレーション

| プロシージャ名 | 種類 | 説明 |
|--------------|------|------|
| `CmdGen_Click_Core(testMode)` | Public Sub | 抽出処理のメインオーケストレーション（Phase 1〜5の各関数を順次呼び出す） |

#### Phase 1: 設定読み込み

| 関数名 | 戻り値 | 説明 |
|-------|-------|------|
| `LoadBasicSettings(targetPattern, noTargetPattern)` | BasicSettings | 基本設定シートから設定値を読み込み、正規表現パターンをByRefで返す |
| `LoadCategoryMappings(testMode)` | Object（Dictionary） | 指摘分類マッピング設定シートを読み込む（E12チェック含む。失敗時は Nothing を返す） |
| `LoadItemMappings()` | MappingConfig | 項目マッピング設定シートを読み込む（34フィールド） |
| `ValidateReviewListInputs(...)` | Boolean | レビュー記録一覧の入力値バリデーション（E01〜E05。True=続行可） |

#### Phase 2: レビュー記録一覧操作

| 関数名 | 戻り値 | 説明 |
|-------|-------|------|
| `OpenReviewListFile(testMode, filepath, sheet, listSheet)` | Workbook | レビュー記録一覧ファイルをオープン（バックアップ作成含む。失敗時は Nothing） |
| `AdjustReviewListCategoryColumns(listSheet, categoryMappings, testMode)` | Boolean | レビュー記録一覧のカテゴリ列数調整（E13照合・列挿入削除・SUM式更新・印刷範囲更新） |

#### Phase 3: SheetTemplate調整

| 関数名 | 戻り値 | 説明 |
|-------|-------|------|
| `AdjustTemplateCategoryColumns(categoryMappings, tplSumifStartCol, catColDiff, actualSumifStart, templateCatCount, savedHelperWidth, savedSumifColWidth)` | Sub | カテゴリ列数調整（列挿入削除・ColumnWidth・条件付き書式・SUM式・印刷範囲）。後続処理に必要な6値をByRefで返す |
| `AdjustTemplateSumifColumns(categoryMappings, tplSumifStartCol, templateSumifCount)` | Sub | SUMIF列数調整 |
| `FixTemplateGapAndFormulas(categoryMappings, tplSumifStartCol, catColDiff, actualSumifStart, templateCatCount, savedHelperWidth, savedSumifColWidth)` | Sub | ギャップ列削除・SUMIF参照修正・列幅復元 |
| `UpdateTemplateHeaders(categoryMappings, tplSumifStartCol, templateSumifCount)` | Sub | 行7/8/14のカテゴリヘッダー書換 |

#### Phase 4: ブックループ処理

| 関数名 | 戻り値 | 説明 |
|-------|-------|------|
| `GetReviewRecordSheets(book, target, count, mappings, testMode, ...)` | Integer | レビュー記録票シート取得・転記行特定（0=成功 / 1=次ブックへスキップ / 2=処理中断） |
| `PrepareOutputSheet(book, count, categoryMappings, ...)` | Worksheet | 出力シート準備（E13検証・既存シート削除・docId採番・テンプレートコピー。失敗時は Nothing） |
| `ExtractReviewComments(book, output, categoryMappings, settings, mappings, ...)` | Sub | 全シートのコメント走査・指摘抽出・出力シート書込・レビュー記録票転記 |
| `WriteToReviewList(listSheet, output, ...)` | Sub | レビュー記録一覧への1行反映（工程/レビュア/レビュイ値の取得もByRefで担当） |
| `WriteToReviewRecordHeader(postingHeaderOutput, mappings, ...)` | Sub | レビュー記録票ヘッダーシートへ工程/ページ数/レビュア/レビュイを転記 |
| `WriteToReviewRecordSummary(postingSummaryOutput, mappings, ...)` | Sub | レビュー記録票サマリーシートへ転記 |
| `CalcPageVolume(book)` | Long | ブック内全ワークシートのページ数合計を算出 |
| `DetermineReviewResult(output, categoryMappings, errcount)` | String | 条件付合格判定ロジック（"合格"/"条件付合格"/"" を返す） |

#### ユーティリティ

| 関数名 | 戻り値 | 説明 |
|-------|-------|------|
| `GetLastChar(str)` | String | 文字列の末尾1文字を返す（空白類・タブ・改行を除去後） |

---

### Module1.bas（ユーティリティ・共通定数・型定義）

#### 公開定数

| 定数名 | 型 | 値 | 説明 |
|-------|---|---|------|
| `ENABLE_PERF_LOG` | Boolean | False | パフォーマンス計測の有効化フラグ（True で計測ON） |
| `SHT_KIHON_SETTINGS` | String | "基本設定" | 基本設定シート名 |
| `SHT_CATEGORY_MAPPINGS` | String | "指摘分類マッピング設定" | 指摘分類マッピング設定シート名 |
| `SHT_ITEM_MAPPINGS` | String | "項目マッピング設定" | 項目マッピング設定シート名 |
| `SHT_REVIEW_RECORD` | String | "レビュー記録票" | レビュー記録票シート名 |
| `SHT_PERF_LOG` | String | "パフォーマンス計測" | パフォーマンス計測シート名 |

#### 公開型定義（User Defined Type）

| 型名 | フィールド | 説明 |
|------|----------|------|
| `BasicSettings` | `useReviewRecord As Boolean`<br/>`useSimpleSummary As Boolean` | 基本設定シートから読み込むブール値設定。VBA Type の Object 制約により、正規表現パターンは `LoadBasicSettings` の ByRef 引数で返す |
| `MappingConfig` | 34フィールド（`headerXxx` 12個・`summaryXxx` 13個・`listXxx` 9個） | 項目マッピング設定シートのマッピング定義（転記先シート名・列・行） |

#### ユーティリティ関数

| 関数名 | 戻り値 | 説明 |
|-------|-------|------|
| `initializeModule1()` | Sub | コメント分割用正規表現オブジェクトを初期化（パターン: `^---+$`） |
| `InitRegexPatterns(targetPattern, noTargetPattern)` | Sub | 基本設定シート B4/B5 から対象・除外ブック名の正規表現パターンを生成（ByRef で呼び出し元に返す） |
| `hasSheet(book, query)` | Boolean | 指定ブックに指定シートが存在するか |
| `inStrCount(s, query)` | Integer | 文字列内の部分文字列出現回数 |
| `repeat(s, cnt)` | String | 文字列をn回繰り返す |
| `nullToZero(v)` | Long | Null・非数値を0に変換 |
| `zeroToNull(v)` | Variant | 0を空文字に変換 |
| `checkReference(book, querysheet, querycell)` | Boolean | セル参照の妥当性チェック |
| `splitComment(comment)` | String() | コメントをレビューコメントと返信コメントに分割（区切り: `---` パターン） |
| `ExtractCategory(commentText)` | String | コメントからカテゴリ（1〜2文字）を抽出 |
| `IsValidCategory(category, categoryMappings)` | Boolean | カテゴリが設定シートに登録済みかチェック |
| `extractCloseLine(commentText)` | String | コメントから「済」を含む行を抽出 |

#### パフォーマンス計測（`ENABLE_PERF_LOG = True` 時のみ有効）

| 関数名 | 戻り値 | 説明 |
|-------|-------|------|
| `InitTimerLog()` | Sub | 計測タイマー初期化 |
| `RecordTimer(label)` | Sub | 計測ポイントの記録 |
| `OutputTimerLog(targetWorkbook)` | Sub | 計測結果をパフォーマンス計測シートへ出力 |

---

### Module2.bas（クリーンアップ処理・メッセージ表示）

| プロシージャ名 | 種類 | 説明 |
|--------------|------|------|
| `ShowMsg(testMode, msgId, msg, msgType, defaultReturn)` | Function (Long) | テスト対応メッセージ表示。`testMode=True` 時は MsgBox を表示せずログに記録してデフォルト値を返す |
| `GetDialogLog()` | Function (String) | テスト用: 表示されたメッセージのログ取得 |
| `ClearDialogLog()` | Sub | テスト用: ダイアログログクリア |
| `DelAllReviewComments_Click()` | Sub | 全レビューコメント削除（UIボタンから呼び出し） |
| `DelAllReviewComments_Click_Core(testMode)` | Public Sub | 全レビューコメント削除のコア処理 |
| `DelAllReviewResultSheets_Click()` | Sub | 全レビュー結果シート削除（UIボタンから呼び出し） |
| `DelAllReviewResultSheets_Click_Core(testMode)` | Public Sub | 全レビュー結果シート削除のコア処理 |
