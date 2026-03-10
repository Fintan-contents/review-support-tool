"""xlsx_diff.py のユニットテスト"""
import pytest
import openpyxl
from datetime import datetime
from pathlib import Path

from helpers.xlsx_diff import (
    compare_cells,
    _build_excluded_set,
    compare_workbooks,
    print_diff_report,
    DiffResult,
)


def _make_workbook(tmp_path, filename, sheet_data: dict) -> str:
    """テスト用xlsxファイルを作成するヘルパー

    Args:
        tmp_path: pytest tmp_path フィクスチャ
        filename: 出力ファイル名
        sheet_data: {シート名: [[row1_vals], [row2_vals], ...]}

    Returns:
        作成したファイルのパス
    """
    wb = openpyxl.Workbook()
    wb.remove(wb.active)  # デフォルトシートを削除
    for sheet_name, rows in sheet_data.items():
        ws = wb.create_sheet(sheet_name)
        for r_idx, row in enumerate(rows, start=1):
            for c_idx, val in enumerate(row, start=1):
                ws.cell(r_idx, c_idx).value = val
    path = str(tmp_path / filename)
    wb.save(path)
    return path


class TestCompareCells:
    """compare_cells 関数のテスト"""

    def test_both_none(self):
        """正常系: 両方Noneは一致"""
        assert compare_cells(None, None) is True

    def test_actual_none_expected_value(self):
        """異常系: 片方のみNoneは不一致"""
        assert compare_cells(None, "value") is False

    def test_expected_none_actual_value(self):
        """異常系: 片方のみNoneは不一致"""
        assert compare_cells("value", None) is False

    def test_matching_strings(self):
        """正常系: 同一文字列は一致"""
        assert compare_cells("hello", "hello") is True

    def test_mismatching_strings(self):
        """異常系: 異なる文字列は不一致"""
        assert compare_cells("hello", "world") is False

    def test_string_with_whitespace(self):
        """正常系: 前後の空白を無視して比較"""
        assert compare_cells("  text  ", "text") is True

    def test_matching_integers(self):
        """正常系: 同一整数は一致"""
        assert compare_cells(42, 42) is True

    def test_matching_int_and_float(self):
        """正常系: 整数と浮動小数点の同値は一致"""
        assert compare_cells(1, 1.0) is True

    def test_numeric_within_tolerance(self):
        """正常系: 浮動小数点誤差許容範囲内は一致"""
        assert compare_cells(0.1 + 0.2, 0.3) is True

    def test_datetime_matching(self):
        """正常系: ほぼ同時刻のdatetimeは一致（1秒未満）"""
        dt1 = datetime(2024, 1, 1, 10, 0, 0)
        dt2 = datetime(2024, 1, 1, 10, 0, 0)
        assert compare_cells(dt1, dt2) is True

    def test_datetime_mismatching(self):
        """異常系: 1秒以上差があるdatetimeは不一致"""
        dt1 = datetime(2024, 1, 1, 10, 0, 0)
        dt2 = datetime(2024, 1, 1, 10, 0, 2)
        assert compare_cells(dt1, dt2) is False


class TestBuildExcludedSet:
    """_build_excluded_set 関数のテスト"""

    def test_empty_list(self):
        """正常系: 空リストは空dictを返す"""
        result = _build_excluded_set([])
        assert result == {}

    def test_none_input(self):
        """正常系: Noneは空dictを返す"""
        result = _build_excluded_set(None)
        assert result == {}

    def test_single_sheet(self):
        """正常系: 1シートのexcluded_cellsを変換"""
        excluded = [{"sheet": "Sheet1", "cells": ["E4", "F4"]}]
        result = _build_excluded_set(excluded)
        assert "Sheet1" in result
        assert result["Sheet1"] == {"E4", "F4"}

    def test_multiple_sheets(self):
        """正常系: 複数シートのexcluded_cellsを変換"""
        excluded = [
            {"sheet": "Sheet1", "cells": ["A1"]},
            {"sheet": "Sheet2", "cells": ["B2", "C3"]},
        ]
        result = _build_excluded_set(excluded)
        assert result["Sheet1"] == {"A1"}
        assert result["Sheet2"] == {"B2", "C3"}


class TestCompareWorkbooks:
    """compare_workbooks 関数のテスト"""

    def test_identical_workbooks(self, tmp_path):
        """正常系: 同一内容のワークブックはmatches=True"""
        data = {"Sheet1": [["A", "B"], ["C", "D"]]}
        actual = _make_workbook(tmp_path, "actual.xlsx", data)
        expected = _make_workbook(tmp_path, "expected.xlsx", data)
        result = compare_workbooks(actual, expected)
        assert result.matches is True
        assert result.diffs == []

    def test_different_cell_value(self, tmp_path):
        """異常系: セル値が異なる場合はmatches=False"""
        data_actual = {"Sheet1": [["A", "B"]]}
        data_expected = {"Sheet1": [["A", "X"]]}
        actual = _make_workbook(tmp_path, "actual.xlsx", data_actual)
        expected = _make_workbook(tmp_path, "expected.xlsx", data_expected)
        result = compare_workbooks(actual, expected)
        assert result.matches is False
        assert len(result.diffs) >= 1

    def test_missing_sheet_in_actual(self, tmp_path):
        """異常系: actualにシートが存在しない場合はmatches=False"""
        actual = _make_workbook(tmp_path, "actual.xlsx", {"OtherSheet": [["A"]]})
        expected = _make_workbook(tmp_path, "expected.xlsx", {"Sheet1": [["A"]]})
        result = compare_workbooks(actual, expected)
        assert result.matches is False
        assert any("missing" in d.lower() for d in result.diffs)

    def test_extra_sheet_in_actual(self, tmp_path):
        """異常系: actualに余分なシートがある場合はmatches=False"""
        actual = _make_workbook(
            tmp_path, "actual.xlsx",
            {"Sheet1": [["A"]], "ExtraSheet": [["X"]]}
        )
        expected = _make_workbook(
            tmp_path, "expected.xlsx",
            {"Sheet1": [["A"]]}
        )
        result = compare_workbooks(actual, expected)
        assert result.matches is False

    def test_excluded_cells_are_skipped(self, tmp_path):
        """正常系: excluded_cells指定のセルは差分として検出されない"""
        data_actual = {"Sheet1": [["A", "2024-01-01"]]}
        data_expected = {"Sheet1": [["A", "2025-12-31"]]}
        actual = _make_workbook(tmp_path, "actual.xlsx", data_actual)
        expected = _make_workbook(tmp_path, "expected.xlsx", data_expected)
        result = compare_workbooks(
            actual, expected,
            excluded_cells=[{"sheet": "Sheet1", "cells": ["B1"]}]
        )
        assert result.matches is True

    def test_invalid_file_path(self, tmp_path):
        """異常系: 存在しないファイルパスはmatches=False"""
        result = compare_workbooks(
            str(tmp_path / "nonexistent.xlsx"),
            str(tmp_path / "also_nonexistent.xlsx")
        )
        assert result.matches is False
        assert len(result.diffs) >= 1

    def test_specific_sheets_comparison(self, tmp_path):
        """正常系: sheets指定時は指定シートのみ比較"""
        data_actual = {"Sheet1": [["A"]], "Sheet2": [["DIFF"]]}
        data_expected = {"Sheet1": [["A"]], "Sheet2": [["ORIG"]]}
        actual = _make_workbook(tmp_path, "actual.xlsx", data_actual)
        expected = _make_workbook(tmp_path, "expected.xlsx", data_expected)
        # Sheet1のみ比較 → Sheet2の差分は無視
        result = compare_workbooks(actual, expected, sheets=["Sheet1"])
        assert result.matches is True


class TestPrintDiffReport:
    """print_diff_report 関数のテスト"""

    def test_no_differences(self, capsys):
        """正常系: 差分なしのときは✓メッセージを出力"""
        result = DiffResult(matches=True, diffs=[])
        print_diff_report(result)
        captured = capsys.readouterr()
        assert "No differences found" in captured.out

    def test_with_differences(self, capsys):
        """異常系: 差分ありのときは✗メッセージと差分内容を出力"""
        result = DiffResult(
            matches=False,
            diffs=["[Sheet1!A1] actual='X' != expected='Y'"]
        )
        print_diff_report(result)
        captured = capsys.readouterr()
        assert "difference" in captured.out
        assert "Sheet1!A1" in captured.out
