"""
Configuration loader for scenario-based testing.
Reads config.yaml from scenario directories to define test steps.
"""

import os
import yaml
from typing import List, Dict, Any


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

    return config


def validate_step(step: Dict[str, Any]) -> None:
    """
    Validate a single step configuration.
    
    Args:
        step: Step dictionary with 'action' and optional parameters
        
    Raises:
        ValueError: If step format is invalid
    """
    if "action" not in step:
        raise ValueError(f"Missing 'action' in step: {step}")
    
    action = step["action"]
    valid_actions = ["extract", "delete_comments", "delete_sheets"]
    
    if action not in valid_actions:
        raise ValueError(f"Invalid action '{action}'. Must be one of {valid_actions}")
    
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
