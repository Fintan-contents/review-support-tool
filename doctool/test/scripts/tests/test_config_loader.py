"""config_loader.py のユニットテスト"""
import pytest
import yaml
from pathlib import Path

from helpers.config_loader import load_scenario_config, validate_step


class TestLoadScenarioConfig:
    """load_scenario_config 関数のテスト"""

    def test_valid_config(self, tmp_path):
        """正常系: stepsを含む有効なconfig.yamlを読み込める"""
        config = {
            "steps": [
                {"action": "extract", "review_times": 1},
                {"action": "delete_comments"},
            ]
        }
        (tmp_path / "config.yaml").write_text(
            yaml.dump(config, allow_unicode=True), encoding="utf-8"
        )
        result = load_scenario_config(str(tmp_path))
        assert result["steps"][0]["action"] == "extract"
        assert len(result["steps"]) == 2

    def test_valid_config_with_optional_keys(self, tmp_path):
        """正常系: オプションキー(skip_open_files, excluded_cells等)を含む設定も読み込める"""
        config = {
            "steps": [{"action": "extract", "review_times": 2}],
            "skip_open_files": True,
            "excluded_cells": [{"sheet": "レビュー結果1回目", "cells": ["E4"]}],
        }
        (tmp_path / "config.yaml").write_text(
            yaml.dump(config, allow_unicode=True), encoding="utf-8"
        )
        result = load_scenario_config(str(tmp_path))
        assert result["skip_open_files"] is True
        assert len(result["excluded_cells"]) == 1

    def test_missing_config_file(self, tmp_path):
        """異常系: config.yamlが存在しない場合はFileNotFoundErrorが発生"""
        with pytest.raises(FileNotFoundError, match="config.yaml not found"):
            load_scenario_config(str(tmp_path))

    def test_invalid_yaml_format(self, tmp_path):
        """異常系: config.yamlがdictでない場合はValueErrorが発生"""
        (tmp_path / "config.yaml").write_text("- item1\n- item2\n", encoding="utf-8")
        with pytest.raises(ValueError, match="Invalid config.yaml format"):
            load_scenario_config(str(tmp_path))

    def test_missing_steps_key(self, tmp_path):
        """異常系: 'steps'キーがない場合はValueErrorが発生"""
        config = {"skip_open_files": True}
        (tmp_path / "config.yaml").write_text(
            yaml.dump(config, allow_unicode=True), encoding="utf-8"
        )
        with pytest.raises(ValueError, match="Missing 'steps'"):
            load_scenario_config(str(tmp_path))

    def test_empty_config_file(self, tmp_path):
        """異常系: 空のconfig.yamlはValueErrorが発生"""
        (tmp_path / "config.yaml").write_text("", encoding="utf-8")
        with pytest.raises(ValueError, match="Invalid config.yaml format"):
            load_scenario_config(str(tmp_path))


class TestValidateStep:
    """validate_step 関数のテスト"""

    def test_valid_extract_step(self):
        """正常系: extractアクションが正しく検証される"""
        step = {"action": "extract", "review_times": 1}
        validate_step(step)  # 例外なしで完了することを確認

    def test_valid_extract_with_repeat(self):
        """正常系: repeatを含むextractステップが検証される"""
        step = {"action": "extract", "review_times": 3, "repeat": 2}
        validate_step(step)  # 例外なしで完了

    def test_valid_delete_comments_step(self):
        """正常系: delete_commentsアクションが検証される"""
        step = {"action": "delete_comments"}
        validate_step(step)  # 例外なしで完了

    def test_valid_delete_sheets_step(self):
        """正常系: delete_sheetsアクションが検証される"""
        step = {"action": "delete_sheets"}
        validate_step(step)  # 例外なしで完了

    def test_missing_action_key(self):
        """異常系: 'action'キーがない場合はValueErrorが発生"""
        step = {"review_times": 1}
        with pytest.raises(ValueError, match="Missing 'action'"):
            validate_step(step)

    def test_invalid_action(self):
        """異常系: 無効なactionはValueErrorが発生"""
        step = {"action": "unknown_action"}
        with pytest.raises(ValueError, match="Invalid action"):
            validate_step(step)

    def test_extract_missing_review_times(self):
        """異常系: extractにreview_timesがない場合はValueErrorが発生"""
        step = {"action": "extract"}
        with pytest.raises(ValueError, match="Missing 'review_times'"):
            validate_step(step)

    def test_extract_invalid_review_times_zero(self):
        """異常系: review_times=0はValueErrorが発生"""
        step = {"action": "extract", "review_times": 0}
        with pytest.raises(ValueError, match="Invalid review_times"):
            validate_step(step)

    def test_extract_invalid_review_times_string(self):
        """異常系: review_timesが文字列の場合はValueErrorが発生"""
        step = {"action": "extract", "review_times": "one"}
        with pytest.raises(ValueError, match="Invalid review_times"):
            validate_step(step)

    def test_extract_invalid_repeat_zero(self):
        """異常系: repeat=0はValueErrorが発生"""
        step = {"action": "extract", "review_times": 1, "repeat": 0}
        with pytest.raises(ValueError, match="Invalid repeat"):
            validate_step(step)
