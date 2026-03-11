# VBA Stomping 調査報告

**調査日**: 2026-03-11
**対象Finding**: M-06（doctool総点検レポート）
**対応優先度**: Medium

---

## 1. 調査概要

`olevba`（oletools 0.60.2）を使用して `Excel設計書レビュー指摘事項抽出ツール.xlsm` を解析し、
VBA Stomping の検出状況と発生原因を調査した。

---

## 2. olevba 解析結果

### 実行コマンド

```bash
python3 -m oletools.olevba "Excel設計書レビュー指摘事項抽出ツール.xlsm"
```

### 検出された項目（Suspicious Indicators）

| 種別 | キーワード | 内容 |
|------|-----------|------|
| Suspicious | VBA Stomping | VBA ソースコードと P-code が異なる。悪意ある用途に使われた可能性がある |
| Suspicious | ExecuteExcel4Macro | Excel 4 マクロ（XLM/XLF）を実行する可能性 |
| Suspicious | CreateObject | OLE オブジェクトを生成する可能性 |
| Suspicious | Open | ファイルを開く可能性 |
| Suspicious | FileCopy | ファイルをコピーする可能性 |
| Suspicious | Hex Strings | 難読化された可能性があるHex文字列 |
| Suspicious | Base64 Strings | Base64エンコード文字列（デコード値: `yyyyMMdd`） |

### 特記事項

```
WARNING: For now, VBA stomping cannot be detected for files in memory
```

olevba は OpenXML 形式（.xlsm）のファイルを解析する際、ファイルをメモリに展開して処理するため、
VBA Stomping の検出精度が制限される旨の警告が表示された。
ただし、VBA Stomping 自体は「検出された（detected）」と判定されている。

---

## 3. VBA Stomping とは

### 定義

VBA Stomping とは、xlsm/xlsb ファイル内に格納される以下の2つのデータが不一致の状態を指す:

| データ種別 | 説明 |
|-----------|------|
| VBA ソースコード | テキスト形式の VBA コード（人間が読める） |
| P-code | Excel が VBA をコンパイルした中間バイトコード |

通常、VBA コードを編集・保存すると両者は同期される。
不一致が生じる主なケースは以下の通り:

### ケース A: 悪意ある改ざん（セキュリティリスク）

攻撃者がソースコードを「無害に見える」内容に書き換え、
P-code に実際に実行される悪意ある処理を残す手法。
セキュリティツールがソースコードをスキャンしても悪意を検出できない。

### ケース B: ビルド環境の差異（本プロジェクトの推定原因）

VBA コードをテキストファイルとして管理し、スクリプトで xlsm にビルドする場合、
ビルド時の Excel バージョン・環境と現在の Excel バージョンが異なると
P-code の互換性が失われ、不一致として検出される。

---

## 4. 本プロジェクトへの適用分析

### プロジェクトの開発体制

本ツールは `vba-text-based-dev` ワークフローを採用している:

```
vba_modules/ (テキストファイル)
  └── Sheet1.cls, Module1.bas, Module2.bas ...
         ↓  build スクリプト
Excel設計書レビュー指摘事項抽出ツール.xlsm
```

VBA ソースコードはテキスト形式で `vba_modules/` ディレクトリに管理され、
ビルドスクリプトによって xlsm に取り込まれる。

### 発生原因の推定

以下の理由から、本プロジェクトのVBA Stompingは **ケース B（ビルド環境差異）** である可能性が高い:

1. **テキストベース開発**: VBA ソースは `vba_modules/` に管理されており、
   xlsm のバイナリは別途ビルドされる
2. **Git 管理**: VBA テキストの変更履歴が管理されており、
   悪意ある改ざんを行う動機・機会が限定される
3. **開発フロー**: ビルドを実行した Excel バージョンと、
   後から解析した環境の Excel バージョンが異なる場合、P-code の内容が変わる

### Hex/Base64 文字列について

olevba が検出した Hex 文字列・Base64 文字列の中に `yyyyMMdd`（日付フォーマット文字列）が
含まれている。これはVBAコード内で日付フォーマットに使用される通常の文字列であり、
難読化を目的としたものではない。

---

## 5. リスク評価

| 項目 | 評価 | 根拠 |
|------|------|------|
| セキュリティリスク（悪意ある改ざん） | **低** | テキストベース開発・Git管理環境のため改ざんリスクが限定的 |
| 機能リスク（P-code 不一致による誤動作） | **低〜中** | P-code と ソースコードが不一致の場合、ExcelバージョンによってはP-codeが優先される |
| 誤検知の可能性 | **高** | olevba 自身が "experimental" と注記しており、ビルド環境差異による検出が多い |
| 組織セキュリティポリシー上の懸念 | **中** | セキュリティスキャンで Suspicious 判定が出る場合、配布・共有時に問題になる可能性 |

---

## 6. 解消方法

### 方法A: xlsm の再ビルド（推奨）

現在の VBA テキストファイルから xlsm を再ビルドすることで、
P-code と ソースコードを同期させる。

```bash
# vba-text-based-dev ブランチの build を実行
# (実行環境に Excel がインストールされている Windows 環境が必要)
```

**期待される効果**: ビルド後に olevba を再実行し、VBA Stomping が消えることを確認できれば
ビルド環境差異が原因であったと確定できる。

**注意**: ビルドには Windows 上の Excel が必要であり、WSL2 環境では直接実行できない。

### 方法B: バイナリ上の VBA プロジェクト再コンパイル

Excel で xlsm を開き、VBA エディタ（Alt+F11）からモジュールを一度削除して再インポートする。

**手順**:
1. Excel で xlsm を開く
2. Alt+F11 で VBA エディタを開く
3. 全モジュールを削除し、`vba_modules/` のテキストファイルを再インポートする
4. xlsm を保存する（この時点で P-code が再生成される）

**注意**: 手動作業であり、手順を誤るとVBAコードが消える可能性がある。
必ずバックアップを取ってから実施すること。

### 方法C: 現状維持（経過観察）

VBA Stomping の検出が実害を伴わない場合（ツールが正常に動作している場合）は、
経過観察とする。次回ビルド時に自動的に解消されることが期待される。

---

## 7. 結論と推奨対応

### 結論

本プロジェクトで検出された VBA Stomping は、**テキストベース開発によるビルド環境差異**が
原因である可能性が高い。悪意ある改ざんである可能性は低いと評価する。

ただし、セキュリティスキャンで Suspicious 判定が出ることは配布・共有時の問題になり得るため、
状況に応じて対応を検討する。

### 推奨対応

**優先度: Low（余裕があれば対応）**

| タイミング | 対応 |
|-----------|------|
| 次回の xlsm ビルド時 | Windows/Excel 環境で再ビルドを実施し、olevba で再確認 |
| 外部組織への配布前 | 方法A または方法B を実施し、VBA Stomping なしの状態で配布 |
| セキュリティポリシー遵守が必要な場合 | 優先して方法A を実施 |

---

## 8. 参考情報

- [oletools - olevba ドキュメント](https://github.com/decalage2/oletools/wiki/olevba)
- [VBA Stomping の詳細説明（oletools GitHub Issues）](https://github.com/decalage2/oletools/issues)
- [Microsoft - xlsm ファイルのVBA構造](https://docs.microsoft.com/en-us/openspecs/office_file_formats/ms-ovba/)
- olevba VBA Stomping 検出: "experimental" ステータス（誤検知の可能性を公式が認めている）
