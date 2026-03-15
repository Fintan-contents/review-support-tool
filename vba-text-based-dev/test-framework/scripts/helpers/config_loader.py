"""
Configuration loader for scenario-based testing.
Reads config.yaml from scenario directories to define test steps.
"""

import os
import yaml
from typing import List, Dict, Any, Optional


def load_scenario_config(scenario_dir: str) -> Dict[str, Any]:
    """
    Load configuration from scenario directory.
    
    Args:
        scenario_dir: Path to scenario directory containing config.yaml
        
    Returns:
        Dictionary with 'steps' and optional keys:
        'skip_open_files', 'excluded_cells', 'file_expectations'
        
    Raises:
        FileNotFoundError: If config.yaml not found
        yaml.YAMLError: If config.yaml parsing fails
    """
    config_path = os.path.join(scenario_dir, "config.yaml")
    
    if not os.path.exists(config_path):
        raise FileNotFoundError(f"config.yaml not found in {scenario_dir}")
    
    with open(config_path, "r", encoding="utf-8") as f:
        config = yaml.safe_load(f)
    
    if not isinstance(config, dict):
        raise ValueError(f"Invalid config.yaml format in {scenario_dir}")
    
    if "steps" not in config:
        raise ValueError(f"Missing 'steps' in config.yaml for {scenario_dir}")

    # compare: セクションのバリデーション（任意キー）
    if "compare" in config:
        _validate_compare_section(config["compare"], scenario_dir)

    return config


def _validate_compare_section(compare: Any, scenario_dir: str) -> None:
    """config.yaml の compare: セクションを検証する。

    Args:
        compare: config["compare"] の値
        scenario_dir: エラーメッセージ用のシナリオディレクトリ

    Raises:
        ValueError: compare セクションの形式が不正な場合
    """
    if not isinstance(compare, dict):
        raise ValueError(
            f"Invalid 'compare' section in {scenario_dir}: must be a mapping"
        )
    valid_keys = {"values", "formulas", "comments", "borders", "column_widths", "print_area", "fill_colors"}
    for key, val in compare.items():
        if key not in valid_keys:
            raise ValueError(
                f"Unknown comparison item '{key}' in {scenario_dir}. "
                f"Valid items: {sorted(valid_keys)}"
            )
        if not isinstance(val, bool):
            raise ValueError(
                f"Comparison item '{key}' must be a boolean in {scenario_dir}, got {type(val).__name__}"
            )


_DEFAULT_VALID_ACTIONS = ["extract", "delete_comments", "delete_sheets"]


def validate_step(
    step: Dict[str, Any],
    valid_actions: Optional[List[str]] = None,
) -> None:
    """
    Validate a single step configuration.

    Args:
        step: Step dictionary with 'action' and optional parameters
        valid_actions: Allowed action names. Defaults to the standard doctool
            action set ["extract", "delete_comments", "delete_sheets"].
            Pass a custom list to support tool-specific actions.

    Raises:
        ValueError: If step format is invalid
    """
    if "action" not in step:
        raise ValueError(f"Missing 'action' in step: {step}")

    action = step["action"]
    allowed = valid_actions if valid_actions is not None else _DEFAULT_VALID_ACTIONS

    if action not in allowed:
        raise ValueError(f"Invalid action '{action}'. Must be one of {allowed}")
    
    if action == "extract":
        if "review_times" not in step:
            raise ValueError(f"Missing 'review_times' for extract action: {step}")
        
        review_times = step["review_times"]
        if not isinstance(review_times, int) or review_times < 1:
            raise ValueError(f"Invalid review_times value: {review_times}")
        
        if "repeat" in step:
            repeat = step["repeat"]
            if not isinstance(repeat, int) or repeat < 1:
                raise ValueError(f"Invalid repeat value: {repeat}")

        if "categories" in step:
            cats = step["categories"]
            if not isinstance(cats, list) or not cats:
                raise ValueError(f"'categories' must be a non-empty list: {cats}")
            for cat in cats:
                if not isinstance(cat, dict) or "alias" not in cat or "name" not in cat:
                    raise ValueError(
                        f"Each category must have 'alias' and 'name' keys: {cat}"
                    )
