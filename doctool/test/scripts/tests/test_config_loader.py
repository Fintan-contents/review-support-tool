"""
config_loader モジュールのユニットテスト

load_scenario_config および validate_step の正常系・異常系を検証する。
"""
import pytest
import yaml
from helpers.config_loader import load_scenario_config, validate_step


# ---------------------------------------------------------------------------
# load_scenario_config
# ---------------------------------------------------------------------------

class TestLoadScenarioConfig:
    """load_scenario_config のテスト"""

    def test_valid_config(self, tmp_path):
        """正常系: steps を含む有効な config.yaml を正しく読み込む"""
        config = {
            "steps": [
                {"action": "extract", "review_times": 1}
            ]
        }
        config_file = tmp_path / "config.yaml"
        config_file.write_text(yaml.dump(config), encoding="utf-8")

        result = load_scenario_config(str(tmp_path))

        assert "steps" in result
        assert len(result["steps"]) == 1
        assert result["steps"][0]["action"] == "extract"

    def test_valid_config_with_optional_keys(self, tmp_path):
        """正常系: 省略可能なキー（skip_open_files, excluded_cells 等）も含む config を読み込む"""
        config = {
            "steps": [{"action": "extract", "review_times": 2}],
            "skip_open_files": True,
            "excluded_cells": [{"sheet": "レビュー結果1回目", "cells": ["E4"]}],
        }
        config_file = tmp_path / "config.yaml"
        config_file.write_text(yaml.dump(config), encoding="utf-8")

        result = load_scenario_config(str(tmp_path))

        assert result["skip_open_files"] is True
        assert len(result["excluded_cells"]) == 1

    def test_config_not_found(self, tmp_path):
        """異常系: config.yaml が存在しない場合 FileNotFoundError を送出する"""
        with pytest.raises(FileNotFoundError):
            load_scenario_config(str(tmp_path))

    def test_config_missing_steps(self, tmp_path):
        """異常系: steps キーが存在しない場合 ValueError を送出する"""
        config_file = tmp_path / "config.yaml"
        config_file.write_text(yaml.dump({"description": "no steps"}), encoding="utf-8")

        with pytest.raises(ValueError, match="Missing 'steps'"):
            load_scenario_config(str(tmp_path))

    def test_config_invalid_format(self, tmp_path):
        """異常系: config.yaml がリスト形式（dict でない）の場合 ValueError を送出する"""
        config_file = tmp_path / "config.yaml"
        config_file.write_text("- item1\n- item2\n", encoding="utf-8")

        with pytest.raises(ValueError, match="Invalid config.yaml format"):
            load_scenario_config(str(tmp_path))


# ---------------------------------------------------------------------------
# validate_step
# ---------------------------------------------------------------------------

class TestValidateStep:
    """validate_step のテスト"""

    def test_valid_extract_step(self):
        """正常系: extract アクション（最低限の必須パラメータ）を検証する"""
        step = {"action": "extract", "review_times": 1}
        validate_step(step)  # 例外が発生しなければ合格

    def test_valid_extract_step_with_repeat(self):
        """正常系: extract アクションに repeat を指定する"""
        step = {"action": "extract", "review_times": 2, "repeat": 3}
        validate_step(step)

    def test_valid_extract_step_with_categories(self):
        """正常系: categories リストを含む extract アクションを検証する"""
        step = {
            "action": "extract",
            "review_times": 1,
            "categories": [
                {"alias": "a", "name": "01_要件漏れ"},
                {"alias": "b", "name": "02_仕様違反"},
            ],
        }
        validate_step(step)

    def test_valid_delete_comments_step(self):
        """正常系: delete_comments アクションを検証する"""
        step = {"action": "delete_comments"}
        validate_step(step)

    def test_valid_delete_sheets_step(self):
        """正常系: delete_sheets アクションを検証する"""
        step = {"action": "delete_sheets"}
        validate_step(step)

    def test_missing_action(self):
        """異常系: action キーが存在しない場合 ValueError を送出する"""
        with pytest.raises(ValueError, match="Missing 'action'"):
            validate_step({"review_times": 1})

    def test_invalid_action(self):
        """異常系: 定義外のアクション名を指定した場合 ValueError を送出する"""
        with pytest.raises(ValueError, match="Invalid action"):
            validate_step({"action": "unknown_action"})

    def test_extract_missing_review_times(self):
        """異常系: extract アクションで review_times が指定されない場合 ValueError を送出する"""
        with pytest.raises(ValueError, match="Missing 'review_times'"):
            validate_step({"action": "extract"})

    def test_extract_invalid_review_times_zero(self):
        """異常系: review_times に 0 を指定した場合 ValueError を送出する"""
        with pytest.raises(ValueError, match="Invalid review_times"):
            validate_step({"action": "extract", "review_times": 0})

    def test_extract_invalid_review_times_negative(self):
        """異常系: review_times に負値を指定した場合 ValueError を送出する"""
        with pytest.raises(ValueError, match="Invalid review_times"):
            validate_step({"action": "extract", "review_times": -1})

    def test_extract_invalid_repeat(self):
        """異常系: repeat に 0 を指定した場合 ValueError を送出する"""
        with pytest.raises(ValueError, match="Invalid repeat"):
            validate_step({"action": "extract", "review_times": 1, "repeat": 0})

    def test_extract_empty_categories(self):
        """異常系: categories が空リストの場合 ValueError を送出する"""
        with pytest.raises(ValueError, match="'categories' must be a non-empty list"):
            validate_step({"action": "extract", "review_times": 1, "categories": []})

    def test_extract_category_missing_alias(self):
        """異常系: categories のエントリに alias キーが存在しない場合 ValueError を送出する"""
        with pytest.raises(ValueError, match="'alias' and 'name'"):
            validate_step(
                {
                    "action": "extract",
                    "review_times": 1,
                    "categories": [{"name": "01_要件漏れ"}],  # alias 欠落
                }
            )

    def test_extract_category_missing_name(self):
        """異常系: categories のエントリに name キーが存在しない場合 ValueError を送出する"""
        with pytest.raises(ValueError, match="'alias' and 'name'"):
            validate_step(
                {
                    "action": "extract",
                    "review_times": 1,
                    "categories": [{"alias": "a"}],  # name 欠落
                }
            )
