"""
S35 テストフィクスチャ生成スクリプト（702カテゴリ対応版）

S29 のフィクスチャをベースに、全702カテゴリ（a～z, aa～zz全組み合わせ）のコメントを
複数シートにまたがって挿入した S35 フィクスチャを生成する。

使用方法:
    cd /home/kuma/work/review-support-tool/doctool/test
    source .venv/bin/activate
    python3 auto/scenario35/create_fixture.py
"""

import shutil
import string
from pathlib import Path
from openpyxl import load_workbook
from openpyxl.comments import Comment

SCRIPT_DIR = Path(__file__).parent
TEST_DIR = SCRIPT_DIR.parent.parent  # doctool/test
S29_DIR = TEST_DIR / "auto" / "scenario29"
S35_DIR = SCRIPT_DIR


def gen_all_categories() -> list:
    """702カテゴリ（a-z + aa-zz全組み合わせ）を生成する。"""
    cats = list(string.ascii_lowercase)  # a-z: 26件
    for c1 in string.ascii_lowercase:
        for c2 in string.ascii_lowercase:
            cats.append(c1 + c2)  # aa-zz: 676件
    return cats  # 合計702件


def add_comment(ws, cell_ref: str, text: str, author: str = "山田　太郎") -> None:
    ws[cell_ref].comment = Comment(text, author)


def remove_existing_comments(ws) -> None:
    for row in ws.iter_rows():
        for cell in row:
            if cell.comment:
                cell.comment = None


def main():
    all_cats = gen_all_categories()
    assert len(all_cats) == 702, f"Expected 702 categories, got {len(all_cats)}"

    # ---- 1. システム機能設計書 フィクスチャ作成 ----
    src_design = S29_DIR / "システム機能設計書_サンプル_S29.xlsx"
    dst_design = S35_DIR / "システム機能設計書_サンプル_S35.xlsx"

    print(f"Loading: {src_design}")
    wb = load_workbook(src_design)

    sheet_names = wb.sheetnames
    print(f"Available sheets: {sheet_names}")

    # コメント挿入対象シートを選定（表紙・変更履歴・目次・データを除く）
    excluded = {"表紙", "変更履歴", "目次", "データ"}
    target_sheets = [s for s in sheet_names if s not in excluded]
    print(f"Target sheets ({len(target_sheets)}): {target_sheets}")

    if len(target_sheets) < 1:
        raise RuntimeError("コメント挿入可能なシートが存在しない")

    # 各シートの既存コメントを削除
    for sn in target_sheets:
        remove_existing_comments(wb[sn])

    # 702カテゴリを均等分散
    num_sheets = len(target_sheets)
    base, rem = divmod(len(all_cats), num_sheets)
    # 各シートに割り当てるカテゴリ
    distributions = []
    start = 0
    for i in range(num_sheets):
        count = base + (1 if i < rem else 0)
        distributions.append((target_sheets[i], all_cats[start:start + count]))
        start += count

    # 日時コメントはSheet1に1件挿入（*カテゴリ）
    ws0 = wb[target_sheets[0]]
    add_comment(
        ws0, "A4",
        "山田　太郎:*\n実施日:2023/08/01\n開始:09:00\n終了:11:00\nレビュー時間:120",
    )

    # 各シートにカテゴリコメントを挿入
    total_inserted = 0
    for sheet_name, categories in distributions:
        ws = wb[sheet_name]
        for idx, alias in enumerate(categories):
            row = 5 + idx  # 1行おき（702件/シートで行が足りるよう1行間隔に変更）
            cell_ref = f"B{row}"
            content = f"{alias}カテゴリの指摘内容サンプル。設計書の記述を確認すること。"
            # 10%程度に済ステータスを付与
            if idx % 10 == 0:
                text = f"山田　太郎:{alias}\n{content}\n---\n対応済みです。\n済"
            else:
                text = f"山田　太郎:{alias}\n{content}"
            add_comment(ws, cell_ref, text)
            total_inserted += 1

    print(f"Saving: {dst_design}")
    wb.save(dst_design)
    print(f"Total category comments inserted: {total_inserted}")

    # ---- 2. カテゴリ総数の確認 ----
    wb_check = load_workbook(dst_design)
    category_found = set()
    for sn in wb_check.sheetnames:
        for row in wb_check[sn].iter_rows():
            for cell in row:
                if cell.comment:
                    text = cell.comment.text
                    colon_pos = text.find(":")
                    if colon_pos >= 0:
                        lf_pos = text.find("\n", colon_pos)
                        if lf_pos < 0:
                            lf_pos = len(text)
                        cat_len = min(lf_pos - colon_pos - 1, 2)
                        if cat_len >= 1:
                            cat = text[colon_pos + 1: colon_pos + 1 + cat_len]
                            if cat != "*":
                                category_found.add(cat)

    print(f"Unique categories found: {len(category_found)}")
    missing = set(all_cats) - category_found
    if missing:
        print(f"WARNING: Missing categories ({len(missing)}): {sorted(missing)[:10]}...")
    else:
        print("OK: All 702 categories are present.")

    # ---- 3. レビュー記録サマリ テンプレートコピー ----
    src_summary = S29_DIR / "レビュー記録サマリ_S29.xlsx"
    dst_summary = S35_DIR / "レビュー記録サマリ_S35.xlsx"
    print(f"Copying summary template: {dst_summary}")
    shutil.copy2(src_summary, dst_summary)

    # ---- 4. レビュー記録票 テンプレートコピー ----
    src_record = S29_DIR / "システム機能設計書_サンプル_S29_レビュー記録票.xlsx"
    dst_record = S35_DIR / "システム機能設計書_サンプル_S35_レビュー記録票.xlsx"
    print(f"Copying review record template: {dst_record}")
    shutil.copy2(src_record, dst_record)

    print("\nDone. Fixture files created:")
    for f in sorted(S35_DIR.glob("*.xlsx")):
        print(f"  {f.name}")


if __name__ == "__main__":
    main()
