"""xlsx_assertions.py のユニットテスト"""
import pytest
import openpyxl

from helpers.xlsx_assertions import (
    get_result_sheet,
    get_detail_rows,
    has_error_sheet,
    count_review_record_issues,
    get_header_info,
    get_category_headers,
    get_category_counts,
    get_review_record_issues,
)


def _make_wb_with_sheets(*sheet_names) -> openpyxl.Workbook:
    """指定シート名のワークブックを作成するヘルパー"""
    wb = openpyxl.Workbook()
    wb.remove(wb.active)
    for name in sheet_names:
        wb.create_sheet(name)
    return wb


def _make_review_result_sheet(wb: openpyxl.Workbook, review_times: int = 1):
    """レビュー結果シートを作成するヘルパー"""
    sheet_name = f"レビュー結果{review_times}回目"
    ws = wb.create_sheet(sheet_name)
    # ヘッダー情報 (row 4)
    ws.cell(4, 1).value = "対象ファイル.xlsx"  # A4: target_file
    ws.cell(4, 3).value = review_times          # C4: review_count
    ws.cell(4, 5).value = "2024-01-15"          # E4: review_date
    ws.cell(4, 6).value = "10:00"               # F4: start_time
    ws.cell(4, 8).value = "11:30"               # H4: end_time
    ws.cell(4, 9).value = "1:30"                # I4: review_time
    # カテゴリヘッダー (row 7, 8)
    ws.cell(7, 2).value = "a"
    ws.cell(7, 3).value = "b"
    ws.cell(8, 2).value = "01_要件漏れ"
    ws.cell(8, 3).value = "02_設計ミス"
    # カテゴリ集計 (row 9=済, row 10=未)
    ws.cell(9, 2).value = 3   # a: 済3件
    ws.cell(10, 2).value = 1  # a: 未1件
    ws.cell(9, 11).value = 4  # 合計済
    ws.cell(10, 11).value = 1 # 合計未
    # 指摘詳細 (row 15〜)
    ws.cell(15, 1).value = "Sheet1"   # DETAIL_COL_SHEET
    ws.cell(15, 2).value = "B5"       # DETAIL_COL_POSITION
    ws.cell(15, 3).value = "Reviewer" # DETAIL_COL_REVIEWER
    ws.cell(15, 4).value = "a"        # DETAIL_COL_CATEGORY
    ws.cell(15, 5).value = "指摘内容" # DETAIL_COL_REVIEW_COMMENT
    ws.cell(15, 11).value = "済"      # DETAIL_COL_FIX_STATUS
    return ws


class TestGetResultSheet:
    """get_result_sheet 関数のテスト"""

    def test_get_first_review_sheet(self):
        """正常系: レビュー結果1回目シートを取得できる"""
        wb = _make_wb_with_sheets("レビュー結果1回目")
        ws = get_result_sheet(wb, 1)
        assert ws.title == "レビュー結果1回目"

    def test_get_second_review_sheet(self):
        """正常系: レビュー結果2回目シートを取得できる"""
        wb = _make_wb_with_sheets("レビュー結果1回目", "レビュー結果2回目")
        ws = get_result_sheet(wb, 2)
        assert ws.title == "レビュー結果2回目"

    def test_missing_sheet_raises_assertion(self):
        """異常系: シートが存在しない場合はAssertionErrorが発生"""
        wb = _make_wb_with_sheets("別のシート")
        with pytest.raises(AssertionError, match="not found"):
            get_result_sheet(wb, 1)


class TestGetDetailRows:
    """get_detail_rows 関数のテスト"""

    def test_returns_rows_with_position(self):
        """正常系: 場所(position)が設定されている行を返す"""
        wb = openpyxl.Workbook()
        wb.remove(wb.active)
        _make_review_result_sheet(wb)
        ws = wb["レビュー結果1回目"]
        rows = get_detail_rows(ws, start_row=15)
        assert len(rows) == 1
        assert rows[0]["position"] == "B5"
        assert rows[0]["reviewer"] == "Reviewer"
        assert rows[0]["fix_status"] == "済"

    def test_skips_rows_without_position(self):
        """正常系: positionが空の行はスキップされる"""
        wb = openpyxl.Workbook()
        wb.remove(wb.active)
        ws = wb.create_sheet("TestSheet")
        # position(B列)が空の行
        ws.cell(15, 1).value = "Sheet1"
        ws.cell(15, 2).value = None  # position empty
        rows = get_detail_rows(ws, start_row=15)
        assert rows == []

    def test_empty_sheet(self):
        """正常系: 空シートは空リストを返す"""
        wb = openpyxl.Workbook()
        ws = wb.active
        rows = get_detail_rows(ws, start_row=15)
        assert rows == []


class TestHasErrorSheet:
    """has_error_sheet 関数のテスト"""

    def test_error_sheet_exists(self):
        """正常系: エラーシートが存在する場合はTrueを返す"""
        wb = _make_wb_with_sheets("エラーシート")
        assert has_error_sheet(wb) is True

    def test_error_sheet_not_exists(self):
        """正常系: エラーシートが存在しない場合はFalseを返す"""
        wb = _make_wb_with_sheets("普通のシート")
        assert has_error_sheet(wb) is False


class TestCountReviewRecordIssues:
    """count_review_record_issues 関数のテスト"""

    def test_count_with_valid_data(self):
        """正常系: 指摘件数を正しくカウント"""
        wb = openpyxl.Workbook()
        wb.remove(wb.active)
        ws = wb.create_sheet("レビュー指摘一覧")
        # B列(review_count_col=2)に値がある行
        ws.cell(5, 2).value = 1
        ws.cell(6, 2).value = 1
        ws.cell(7, 2).value = 1
        count = count_review_record_issues(wb)
        assert count == 3

    def test_stops_at_end_marker(self):
        """正常系: A列のENDマーカーで集計終了"""
        wb = openpyxl.Workbook()
        wb.remove(wb.active)
        ws = wb.create_sheet("レビュー指摘一覧")
        ws.cell(5, 2).value = 1
        ws.cell(6, 1).value = "END"  # ENDマーカー
        ws.cell(6, 2).value = 1       # この行はカウントされない
        count = count_review_record_issues(wb)
        assert count == 1

    def test_missing_sheet_returns_zero(self):
        """異常系: シートが存在しない場合は0を返す"""
        wb = _make_wb_with_sheets("別のシート")
        count = count_review_record_issues(wb)
        assert count == 0


class TestGetHeaderInfo:
    """get_header_info 関数のテスト"""

    def test_returns_header_dict(self):
        """正常系: ヘッダー情報の辞書を返す"""
        wb = openpyxl.Workbook()
        wb.remove(wb.active)
        _make_review_result_sheet(wb, 1)
        ws = wb["レビュー結果1回目"]
        info = get_header_info(ws)
        assert info["target_file"] == "対象ファイル.xlsx"
        assert info["review_count"] == 1
        assert info["review_date"] == "2024-01-15"
        assert info["start_time"] == "10:00"

    def test_empty_header(self):
        """正常系: 空シートはNone値を含む辞書を返す"""
        wb = openpyxl.Workbook()
        ws = wb.active
        info = get_header_info(ws)
        assert "target_file" in info
        assert info["target_file"] is None


class TestGetCategoryHeaders:
    """get_category_headers 関数のテスト"""

    def test_returns_abbreviations_and_names(self):
        """正常系: カテゴリ略称とカテゴリ名を返す"""
        wb = openpyxl.Workbook()
        wb.remove(wb.active)
        _make_review_result_sheet(wb, 1)
        ws = wb["レビュー結果1回目"]
        headers = get_category_headers(ws)
        assert "a" in headers["abbreviations"]
        assert "b" in headers["abbreviations"]
        assert "01_要件漏れ" in headers["names"]

    def test_empty_sheet_returns_empty_lists(self):
        """正常系: カテゴリがない場合は空リストを返す"""
        wb = openpyxl.Workbook()
        ws = wb.active
        headers = get_category_headers(ws)
        assert headers["abbreviations"] == []
        assert headers["names"] == []


class TestGetCategoryCounts:
    """get_category_counts 関数のテスト"""

    def test_returns_category_counts(self):
        """正常系: カテゴリ別集計を返す"""
        wb = openpyxl.Workbook()
        wb.remove(wb.active)
        _make_review_result_sheet(wb, 1)
        ws = wb["レビュー結果1回目"]
        counts = get_category_counts(ws)
        assert counts["fixed"].get("a") == 3
        assert counts["unfixed"].get("a") == 1
        assert counts["fixed_total"] == 4
        assert counts["unfixed_total"] == 1


class TestGetReviewRecordIssues:
    """get_review_record_issues 関数のテスト"""

    def test_returns_issue_list(self):
        """正常系: 指摘一覧を辞書リストで返す"""
        wb = openpyxl.Workbook()
        wb.remove(wb.active)
        ws = wb.create_sheet("レビュー指摘一覧")
        # 列定義: B=review_count, C=position, D=category, E=reviewer
        ws.cell(5, 2).value = 1
        ws.cell(5, 3).value = "A1"
        ws.cell(5, 4).value = "a"
        ws.cell(5, 5).value = "Taro"
        ws.cell(5, 7).value = "済"
        ws.cell(5, 8).value = "コメント内容"
        issues = get_review_record_issues(wb)
        assert len(issues) == 1
        assert issues[0]["position"] == "A1"
        assert issues[0]["category"] == "a"
        assert issues[0]["reviewer"] == "Taro"
        assert issues[0]["fix_status"] == "済"

    def test_stops_at_end_marker(self):
        """正常系: ENDマーカーで読み取り終了"""
        wb = openpyxl.Workbook()
        wb.remove(wb.active)
        ws = wb.create_sheet("レビュー指摘一覧")
        ws.cell(5, 2).value = 1
        ws.cell(5, 3).value = "A1"
        ws.cell(6, 1).value = "END"  # ENDマーカー
        ws.cell(6, 2).value = 1      # この行はスキップされる
        issues = get_review_record_issues(wb)
        assert len(issues) == 1

    def test_missing_sheet_returns_empty_list(self):
        """異常系: シートが存在しない場合は空リストを返す"""
        wb = _make_wb_with_sheets("別のシート")
        issues = get_review_record_issues(wb)
        assert issues == []
