# VBAモジュール構成

---

## モジュール一覧

| モジュール名 | 種類 | 行数 | 説明 |
|------------|------|------|------|
| `Sheet1.cls` | クラスモジュール | 1473行 | **メイン処理**（レビュー指摘事項抽出シート） |
| `Module1.bas` | 標準モジュール | 231行 | **ユーティリティ関数群** |
| `Module2.bas` | 標準モジュール | 159行 | **クリーンアップ処理**（コメント・シート削除） |
| `Sheet8.cls` | クラスモジュール | 31行 | 不明（抽出結果で中身なし） |
| `ThisWorkbook.cls` | クラスモジュール | 2行 | 空 |
| `SheetTemplate.cls` | クラスモジュール | 2行 | 空（レビュー結果シートテンプレート） |
| `ErrorSheetTemplate.cls` | クラスモジュール | 2行 | 空（エラーシートテンプレート） |
| `Sheet2.cls`～`Sheet7.cls` | クラスモジュール | 各2行 | 空（各種シートのクラス） |

---

## 主要プロシージャ一覧

### Sheet1.cls（メイン処理）

| プロシージャ名 | 種類 | 説明 |
|--------------|------|------|
| `CmdGen_Click()` | イベント | **レビュー指摘事項抽出ボタンクリック時のメイン処理** |
| `CbAdjustCmntPos_Click()` | イベント | コメント位置調整チェックボックス |
| `CheckBox1_Click()` | イベント | チェックボックス（用途不明） |

### Module1.bas（ユーティリティ）

| 関数名 | 戻り値 | 説明 |
|-------|-------|------|
| `initializeModule1()` | Sub | モジュールの初期化（正規表現オブジェクト作成） |
| `hasSheet(book, query)` | Boolean | 指定ブックに指定シートが存在するか |
| `inStrCount(s, query)` | Integer | 文字列内の部分文字列出現回数をカウント |
| `repeat(s, cnt)` | String | 文字列をn回繰り返す |
| `nullToZero(v)` | Long | Null値を0に変換 |
| `zeroToNull(v)` | Variant | 0を空文字に変換 |
| `checkReference(book, sheet, cell)` | Boolean | セル参照の妥当性をチェック |
| `splitComment(comment)` | String() | コメントを「レビューコメント」と「返信コメント」に分割 |
| `extractCloseLine(commentText)` | String | コメントから「済」を含む行を抽出 |
| `ExtractCategory(commentText)` | String | コメントからカテゴリ（1-2文字）を抽出 |
| `IsValidCategory(category, categoryMappings)` | Boolean | カテゴリが設定シートに登録済みかチェック |

### Module2.bas（クリーンアップ）

| プロシージャ名 | 種類 | 説明 |
|--------------|------|------|
| `DelAllReviewComments_Click()` | Sub | 全レビューコメント削除 |
| `DelAllReviewResultSheets_Click()` | Sub | 全レビュー結果シート削除 |
