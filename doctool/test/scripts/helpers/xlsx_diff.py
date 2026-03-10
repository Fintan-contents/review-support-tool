"""Excel ワークブック差分比較モジュール

期待結果xlsx（Gold Master）と実際の出力xlsxを比較し、差分を検出する。
"""
import openpyxl
from dataclasses import dataclass
from datetime import datetime
from typing import Optional


@dataclass
class DiffResult:
    """差分比較結果"""
    matches: bool
    diffs: list[str]


def compare_cells(actual, expected) -> bool:
    """型を考慮したセル値の比較
    
    Args:
        actual: 実際のセル値
        expected: 期待されるセル値
        
    Returns:
        bool: 値が一致する場合True
    """
    # 両方Noneの場合は一致
    if actual is None and expected is None:
        return True
    
    # どちらか一方のみNoneの場合は不一致
    if actual is None or expected is None:
        return False
    
    # datetime型の比較（1秒未満の誤差を許容）
    if isinstance(actual, datetime) and isinstance(expected, datetime):
        return abs((actual - expected).total_seconds()) < 1
    
    # 数値型の比較（浮動小数点誤差を考慮）
    if isinstance(actual, (int, float)) and isinstance(expected, (int, float)):
        return abs(float(actual) - float(expected)) < 1e-9
    
    # その他は文字列として比較
    return str(actual).strip() == str(expected).strip()


def _build_excluded_set(excluded_cells: list[dict]) -> dict[str, set[str]]:
    """excluded_cells 設定をシート名 → セル座標のセットに変換

    Args:
        excluded_cells: config.yaml の excluded_cells リスト
            例: [{"sheet": "レビュー結果1回目", "cells": ["E4", "F4"]}]

    Returns:
        dict: {シート名: {座標, ...}}
    """
    result = {}
    for entry in excluded_cells or []:
        sheet = entry.get("sheet", "")
        cells = set(entry.get("cells", []))
        if sheet:
            result.setdefault(sheet, set()).update(cells)
    return result


def compare_workbooks(
    actual_path: str,
    expected_path: str,
    sheets: Optional[list[str]] = None,
    excluded_cells: Optional[list[dict]] = None,
    ignore_format: bool = True,
    max_diffs: int = 10
) -> DiffResult:
    """2つのxlsxファイルをセル値ベースで比較する

    Args:
        actual_path: 実際の出力xlsxファイルパス
        expected_path: 期待結果xlsxファイルパス
        sheets: 比較対象シート名リスト（Noneの場合は期待結果の全シートを比較）
        excluded_cells: 比較をスキップするセルの定義
            例: [{"sheet": "レビュー結果1回目", "cells": ["E4"]}]
            毎回変わる実施日時などのセルに使用する
        ignore_format: フォーマット（色・罫線等）を無視（現在は常にTrue）
        max_diffs: 報告する差分の最大数（デバッグ容易性のため制限）

    Returns:
        DiffResult: 比較結果（一致/不一致 + 差分詳細リスト）
    """
    try:
        actual = openpyxl.load_workbook(actual_path, data_only=True)
        expected = openpyxl.load_workbook(expected_path, data_only=True)
    except Exception as e:
        return DiffResult(matches=False, diffs=[f"Failed to load workbooks: {e}"])

    diffs = []
    excluded = _build_excluded_set(excluded_cells)

    # 比較対象シートの決定（Noneの場合は期待結果の全シート）
    target_sheets = sheets if sheets is not None else expected.sheetnames

    for sheet_name in target_sheets:
        # シート存在チェック
        if sheet_name not in actual.sheetnames:
            diffs.append(f"Sheet '{sheet_name}' missing in actual workbook")
            if len(diffs) >= max_diffs:
                break
            continue

        if sheet_name not in expected.sheetnames:
            diffs.append(f"Sheet '{sheet_name}' missing in expected workbook")
            if len(diffs) >= max_diffs:
                break
            continue

        aws = actual[sheet_name]
        ews = expected[sheet_name]
        excluded_coords = excluded.get(sheet_name, set())

        # 行数・列数の比較
        if aws.max_row != ews.max_row:
            diffs.append(
                f"[{sheet_name}] Row count mismatch: "
                f"actual={aws.max_row}, expected={ews.max_row}"
            )

        if aws.max_column != ews.max_column:
            diffs.append(
                f"[{sheet_name}] Column count mismatch: "
                f"actual={aws.max_column}, expected={ews.max_column}"
            )

        # セル値・コメントの完全一致比較
        max_row = max(aws.max_row or 0, ews.max_row or 0)
        max_col = max(aws.max_column or 0, ews.max_column or 0)

        for row in range(1, max_row + 1):
            for col in range(1, max_col + 1):
                cell_ref = aws.cell(row, col).coordinate

                # excluded_cells に指定されたセルはスキップ
                if cell_ref in excluded_coords:
                    continue

                av = aws.cell(row, col).value
                ev = ews.cell(row, col).value

                if not compare_cells(av, ev):
                    av_str = str(av)[:50] + "..." if av and len(str(av)) > 50 else str(av)
                    ev_str = str(ev)[:50] + "..." if ev and len(str(ev)) > 50 else str(ev)
                    diffs.append(
                        f"[{sheet_name}!{cell_ref}] actual='{av_str}' != expected='{ev_str}'"
                    )

                    if len(diffs) >= max_diffs:
                        diffs.append(f"... (差分数が{max_diffs}件を超えたため省略)")
                        return DiffResult(matches=False, diffs=diffs)

                # コメント（メモ）の比較
                ac = aws.cell(row, col).comment
                ec = ews.cell(row, col).comment
                ac_text = ac.text.strip() if ac else None
                ec_text = ec.text.strip() if ec else None
                if ac_text != ec_text:
                    ac_repr = repr(ac_text[:50] + "...") if ac_text and len(ac_text) > 50 else repr(ac_text)
                    ec_repr = repr(ec_text[:50] + "...") if ec_text and len(ec_text) > 50 else repr(ec_text)
                    diffs.append(
                        f"[{sheet_name}!{cell_ref}] comment: actual={ac_repr} != expected={ec_repr}"
                    )

                    if len(diffs) >= max_diffs:
                        diffs.append(f"... (差分数が{max_diffs}件を超えたため省略)")
                        return DiffResult(matches=False, diffs=diffs)

        if len(diffs) >= max_diffs:
            diffs.append(f"... (差分数が{max_diffs}件を超えたため省略)")
            break

    return DiffResult(matches=len(diffs) == 0, diffs=diffs)


def print_diff_report(result: DiffResult) -> None:
    """差分レポートをコンソールに出力
    
    Args:
        result: 差分比較結果
    """
    if result.matches:
        print("✓ No differences found")
    else:
        print(f"✗ Found {len(result.diffs)} difference(s):")
        for i, diff in enumerate(result.diffs, 1):
            print(f"  {i}. {diff}")
