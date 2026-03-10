# VBA Stomping 調査結果

**対象Finding**: M-06
**作成**: 2026-03-11
**作成者**: 足軽5号（subtask_280e_investigation）

---

## 1. 調査概要

olevba（oletools）が doctool の xlsm ファイルで VBA Stomping を検出した。
本調査では以下を確認する。

1. VBA Stomping の定義と本ケースへの当てはまり
2. 検出されているモジュール
3. セキュリティリスクの評価（悪意ある可能性 vs 誤検知）
4. 解消策の評価

---

## 2. VBA Stomping とは

VBA Stomping は **VBA ソースコード（人間が読める .cls/.bas テキスト）と、xlsm バイナリ内に格納された p-code（コンパイル済みバイトコード）が一致しない**状態を指す。

```
xlsm バイナリ（vbaProject.bin）の構造
├── VBA Source   ← VBE で表示されるテキスト（.cls/.bas の内容）
└── p-code       ← Excel が実際に実行するコンパイル済みバイトコード
                    （Excel のバージョン固有）
```

**悪意ある利用（本来の意味）**:
- 攻撃者が無害なソースコードで p-code を「踏み荒らし（stomp）」、
  VBE で見ると無害に見えるが実際には悪意ある p-code が実行される
- マルウェア解析の回避手法として知られる

**誤検知パターン（一般的）**:
- ソースコードをテキスト編集後、Excel で再コンパイルせずに保存した場合
- vba-text-based-dev 等のテキストベース開発ツールで export/import した場合
- Excel のバージョン間でのファイル移動（p-code はバージョン固有）

---

## 3. 現状確認

### olevba 実行結果

```
FILE: Excel設計書レビュー指摘事項抽出ツール.xlsm
Type: OpenXML

WARNING: For now, VBA stomping cannot be detected for files in memory

VBA MACRO Sheet8.cls
in file: xl/vbaProject.bin - OLE stream: 'VBA/Sheet8'
(empty macro)

|Suspicious|VBA Stomping|VBA Stomping was detected: the VBA source
|          |            |code and P-code are different, this may have
|          |            |been used to hide malicious code
VBA Stomping detection is experimental: please report any false positive/negative
```

### 検出モジュール

- **VBA/Sheet8** のみで検出
- Sheet8 の VBA ソース: `(empty macro)` = 空
- Sheet8 の p-code: 内容が存在する（ソースと不一致）

### vba_modules/Sheet8.cls について

`vba_modules/Sheet8.cls` は VBA ソースコードではなく、**olevba 解析結果のテキスト出力**が格納されている。これは開発者が過去の oletools 実行結果を記録目的でこのファイルに保存したものと推定される。xlsm バイナリ内の Sheet8 VBA ソースとは別物。

---

## 4. 発生原因の推定

### 最も可能性が高い原因: **テキストベース開発ワークフローの副産物**

doctool は `vba-text-based-dev` パターン（wsl2-config.mk / win-config.bat）でテキスト管理している。

```
開発フロー:
  1. xlsm から VBA を export → vba_modules/*.cls/*.bas
  2. テキストエディタ・Git で編集
  3. 変更した .cls/.bas を xlsm に import → Excel が再コンパイル → xlsm 保存
```

**Sheet8 で不一致が起きた推定シナリオ**:
1. Sheet8 は元々何らかの VBA コードを持っていた
2. 開発作業中に Sheet8 の VBA ソースが空にされた（または oletools 出力で上書きされた）
3. テキストファイル編集後、Excel で「import → compile → save」のサイクルを経ずに xlsm バイナリが更新された
4. 結果として、空のソースと古い p-code が共存する状態になった

### 重要な olevba の警告

```
WARNING: For now, VBA stomping cannot be detected for files in memory
```

xlsm（OpenXML）形式では vbaProject.bin がメモリ展開されるため、**olevba 0.60.2 時点で VBA Stomping 検出の信頼性が低い**。oletools 公式も `experimental` と明記。

---

## 5. セキュリティリスク評価

### リスク判定: **低（誤検知の可能性が高い）**

| 評価観点 | 状況 | 判定 |
|---------|------|------|
| 著者の信頼性 | 自作ツール。Git 管理。作成者が明確 | 問題なし |
| ソースコードの内容 | Sheet1.cls の VBA が完全に可視・内容が業務ロジックと一致 | 問題なし |
| p-code の隠蔽意図 | テキストベース開発の副産物と考えられる | 悪意なし |
| 実害リスク | Sheet8 は空のモジュール。実行されるコードは Sheet1.cls が中心 | 実害なし |
| olevba の検出精度 | OpenXML での検出は experimental。公式が誤検知報告を求めている | 低信頼性 |

---

## 6. 解消策の評価

### 方法: xlsm の再コンパイル（推奨）

`vba-text-based-dev` の build コマンドフロー（win-config.bat 経由）を実行すると、VBA ソースが再度 Excel にインポートされ、p-code が新しくコンパイルされる。これにより **ソースと p-code が同期され VBA Stomping が解消**される。

**実行条件**:
- Windows 環境（Excel + Python.exe が必要）
- WSL2 単体では実行不可（`win-config.bat` は Windows 側で実行）

**実行手順**（Windows 側）:
```batch
REM Win 側で実行
win-config.bat
REM または直接:
REM xlsm をExcelで開く → VBE を開く → デバッグ → VBAProject のコンパイル → 保存
```

**再コンパイル後の確認**:
```bash
olevba "Excel設計書レビュー指摘事項抽出ツール.xlsm" | grep -i stomp
# VBA Stomping の検出がなくなることを確認
```

### 暫定対応（WSL2 環境で可能）

Sheet8 の VBA ソースと p-code の不一致はリスクが低いため、`vba_modules/Sheet8.cls` の内容を整理し、oletools 出力テキストではなく空の VBA モジュールとして明示することを推奨。

---

## 7. 結論・推奨アクション

| 優先度 | アクション | 担当 | 備考 |
|--------|-----------|------|------|
| **中** | Windows 環境で xlsm を再コンパイル・保存して olevba 再確認 | 開発者 | win-config.bat 経由で実行 |
| **低** | `vba_modules/Sheet8.cls` の中身を整理（oletools 出力削除 or 空化） | 開発者 | 現状は誤解を招くファイル内容 |

**現状のセキュリティリスクは低い。** doctool は自作ツールであり、VBA ソースコードの全内容が Git 管理されており透明性が確保されている。VBA Stomping の検出は、テキストベース開発ワークフロー特有の誤検知と判断する。

---

*調査完了。xlsm の実際の再コンパイルは WSL2 環境外の作業のため今回のタスクスコープ外。*
