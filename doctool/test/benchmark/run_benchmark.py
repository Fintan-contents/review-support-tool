"""
カテゴリ数別パフォーマンスベンチマーク

指定したカテゴリ数のフィクスチャを動的生成し、VBA マクロの実行時間を計測する。
計測結果は CSV ファイルとコンソールに出力される。

使用方法:
    cd doctool/test
    set TOOL_TEST_ROOT=%CD%
    python benchmark/run_benchmark.py
    python benchmark/run_benchmark.py --categories 10 30 50   # 指定カテゴリ数のみ
    python benchmark/run_benchmark.py --dry-run               # フィクスチャ生成のみ（VBA実行なし）
"""

import argparse
import csv
import gc
import os
import shutil
import string
import sys
import time
from datetime import datetime
from pathlib import Path

# benchmark/ ディレクトリの親 (doctool/test) を sys.path に追加し、
# test-framework のヘルパーを利用できるようにする
BENCHMARK_DIR = Path(__file__).parent
TEST_DIR = BENCHMARK_DIR.parent
FRAMEWORK_DIR = TEST_DIR.parent.parent / "vba-text-based-dev" / "test-framework" / "scripts"

sys.path.insert(0, str(FRAMEWORK_DIR))

import yaml

try:
    import pywintypes
    import xlwings as xw
    XLWINGS_AVAILABLE = True
except ImportError:
    XLWINGS_AVAILABLE = False

from create_fixture import create_fixture


# ============================================================
# 設定
# ============================================================

DEFAULT_CATEGORY_COUNTS = [
    1, 10, 20, 30, 40, 50, 60, 70, 80, 90,
    100, 200, 300, 400, 500, 600, 700, 702,
]

TOOL_CONFIG_PATH = TEST_DIR / "tool_config.yaml"
TMP_DIR = BENCHMARK_DIR / "tmp"
RESULTS_DIR = BENCHMARK_DIR / "results"


def _load_xlsm_path() -> Path:
    with open(TOOL_CONFIG_PATH, encoding="utf-8") as f:
        cfg = yaml.safe_load(f)
    return (TEST_DIR / cfg["xlsm_path"]).resolve()


def _load_xlsm_name() -> str:
    with open(TOOL_CONFIG_PATH, encoding="utf-8") as f:
        cfg = yaml.safe_load(f)
    return cfg["xlsm_name"]


# ============================================================
# カテゴリエイリアス生成
# ============================================================

def gen_aliases(n: int) -> list[str]:
    aliases: list[str] = []
    for c in string.ascii_lowercase:
        aliases.append(c)
        if len(aliases) >= n:
            return aliases
    for first in string.ascii_lowercase:
        for second in string.ascii_lowercase:
            aliases.append(first + second)
            if len(aliases) >= n:
                return aliases
    return aliases


# ============================================================
# VBA 実行
# ============================================================

def run_vba(work_dir: Path, categories: int) -> tuple[float, str]:
    """VBA マクロを実行し、(実行時間秒, ステータス) を返す。

    ステータス: "success" | "error:<message>"
    """
    xlsm_src = _load_xlsm_path()
    xlsm_name = _load_xlsm_name()
    xlsm_dest = work_dir / xlsm_name
    shutil.copy2(xlsm_src, xlsm_dest)

    aliases = gen_aliases(categories)
    app = None

    try:
        app = xw.App(visible=False)

        # Excel 起動時の自動作成デフォルトブックを閉じる
        for book in list(app.books):
            try:
                book.close()
            except Exception:
                pass

        # 設計書を開く
        design_path = next(
            (f for f in work_dir.glob("*.xlsx") if "レビュー記録" not in f.name),
            None,
        )
        if design_path is None:
            return 0.0, "error: 設計書 xlsx が見つかりません"

        design_wb = app.books.open(str(design_path))
        xlsm_wb = app.books.open(str(xlsm_dest))

        # 基本設定: レビュー記録票・サマリ使用
        settings_ws = xlsm_wb.sheets["基本設定"]
        settings_ws["B2"].value = True  # use_review_record
        settings_ws["B3"].value = True  # use_summary

        # レビュー記録サマリのパスを設定
        summary_path = work_dir / "レビュー記録サマリ_bench.xlsx"
        if summary_path.exists():
            xlsm_wb.names["REVIEW_LIST_FILEPATH"].refers_to_range.value = str(summary_path)

        # カテゴリマッピングを設定
        cat_ws = xlsm_wb.sheets["指摘分類マッピング設定"]
        last_row = cat_ws.range("A1").current_region.last_cell.row
        if last_row >= 2:
            cat_ws.range(f"A2:B{last_row}").clear_contents()
        for i, alias in enumerate(aliases, start=2):
            cat_ws.range(f"A{i}").value = alias
            cat_ws.range(f"B{i}").value = f"{i - 1:02d}_{alias}カテゴリ"

        # REVIEW_TIMES を設定
        xlsm_wb.names["REVIEW_TIMES"].refers_to_range.value = 1

        # マクロ実行・時間計測
        macro = xlsm_wb.macro("Sheet1.CmdGen_Click_Core")
        start_time = time.perf_counter()
        macro(True)  # testMode=True
        elapsed = time.perf_counter() - start_time

        # 保存
        design_wb.save()
        xlsm_wb.save()

        return elapsed, "success"

    except Exception as e:
        return 0.0, f"error: {e}"

    finally:
        _cleanup_excel(app)


def _cleanup_excel(app) -> None:
    if app is None:
        return
    try:
        for book in list(app.books):
            try:
                book.close()
            except Exception:
                pass
    except Exception:
        pass
    gc.collect()
    try:
        app.quit()
    except Exception:
        pass
    gc.collect()

    # Excel プロセス終了確認（最大 10 秒）
    try:
        import psutil
        for _ in range(10):
            if not any(p.name().lower() == "excel.exe" for p in psutil.process_iter(["name"])):
                break
            time.sleep(1)
    except Exception:
        pass


# ============================================================
# ベンチマーク本体
# ============================================================

def run_benchmark(category_counts: list[int], dry_run: bool = False) -> list[dict]:
    results = []

    for n in category_counts:
        work_dir = TMP_DIR / f"bench_{n}"
        if work_dir.exists():
            shutil.rmtree(work_dir)

        print(f"\n[{n:3d} categories] フィクスチャ生成中...")
        try:
            create_fixture(n, work_dir)
        except Exception as e:
            print(f"  ERROR (fixture): {e}")
            results.append({
                "categories": n,
                "execution_time_sec": "",
                "status": f"error: fixture generation failed: {e}",
                "error_message": str(e),
            })
            continue

        if dry_run:
            print(f"  [dry-run] VBA 実行をスキップ")
            results.append({
                "categories": n,
                "execution_time_sec": "",
                "status": "dry-run",
                "error_message": "",
            })
            continue

        if not XLWINGS_AVAILABLE:
            print(f"  [skip] xlwings が利用できません（Windows 環境で実行してください）")
            results.append({
                "categories": n,
                "execution_time_sec": "",
                "status": "skip: xlwings not available",
                "error_message": "",
            })
            continue

        print(f"  VBA 実行中...")
        elapsed, status = run_vba(work_dir, n)

        if status == "success":
            print(f"  完了: {elapsed:.2f}s")
        else:
            print(f"  {status}")

        results.append({
            "categories": n,
            "execution_time_sec": f"{elapsed:.3f}" if status == "success" else "",
            "status": status,
            "error_message": "" if status == "success" else status,
        })

    return results


def save_csv(results: list[dict]) -> Path:
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    csv_path = RESULTS_DIR / f"benchmark_{timestamp}.csv"
    with open(csv_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(
            f,
            fieldnames=["categories", "execution_time_sec", "status", "error_message"],
        )
        writer.writeheader()
        writer.writerows(results)
    return csv_path


def print_summary(results: list[dict]) -> None:
    sep = "=" * 55
    print(f"\n{sep}")
    print("ベンチマーク結果サマリー")
    print(sep)
    print(f"{'カテゴリ数':>10}  {'実行時間(秒)':>14}  ステータス")
    print("-" * 55)
    for r in results:
        cat = r["categories"]
        t = r["execution_time_sec"] or "-"
        status = r["status"]
        print(f"{cat:>10}  {t:>14}  {status}")
    print(sep)


# ============================================================
# エントリポイント
# ============================================================

def main() -> None:
    parser = argparse.ArgumentParser(
        description="カテゴリ数別 VBA マクロパフォーマンスベンチマーク"
    )
    parser.add_argument(
        "--categories", "-c",
        type=int,
        nargs="+",
        default=None,
        help="計測するカテゴリ数（省略時はデフォルトリスト全件）",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="フィクスチャ生成のみ実行し、VBA 実行はスキップする",
    )
    args = parser.parse_args()

    category_counts = args.categories if args.categories else DEFAULT_CATEGORY_COUNTS

    print("=" * 55)
    print("VBA マクロ パフォーマンスベンチマーク")
    print(f"計測対象: {category_counts}")
    print(f"モード: {'dry-run' if args.dry_run else '実行'}")
    print("=" * 55)

    # TOOL_TEST_ROOT が必要（scenario_runner.py と同じ方式）
    if "TOOL_TEST_ROOT" not in os.environ:
        os.environ["TOOL_TEST_ROOT"] = str(TEST_DIR)

    results = run_benchmark(category_counts, dry_run=args.dry_run)

    print_summary(results)

    csv_path = save_csv(results)
    print(f"\n結果を保存しました: {csv_path}")


if __name__ == "__main__":
    main()
