"""テストフィクスチャ管理モジュール

フィクスチャの一時コピー、リセット機能を提供する。
"""
import os
import shutil
import tempfile
from pathlib import Path
from typing import Optional


FIXTURE_BASE = Path(os.environ["TOOL_TEST_ROOT"]) / "auto"


def prepare_scenario(
    scenario_name: str,
    work_dir: Optional[Path] = None
) -> Path:
    """フィクスチャを一時ディレクトリにコピーし、パスを返す

    Args:
        scenario_name: シナリオ名（例: "scenario01"）
        work_dir: 作業ディレクトリ（指定しない場合は一時ディレクトリを自動作成）

    Returns:
        作業ディレクトリ内のシナリオディレクトリパス

    Raises:
        FileNotFoundError: フィクスチャが存在しない場合
    """
    src = FIXTURE_BASE / scenario_name

    if not src.exists():
        raise FileNotFoundError(
            f"Fixture directory not found: {src}. "
            f"Available scenarios: {list_scenarios()}"
        )

    # 作業ディレクトリの決定
    if work_dir is None:
        work_dir = Path(tempfile.mkdtemp(prefix=f"review_test_{scenario_name}_"))

    dest = work_dir / scenario_name

    # フィクスチャをコピー
    shutil.copytree(src, dest, dirs_exist_ok=True)

    return dest


def list_scenarios() -> list[str]:
    """利用可能なシナリオ名のリストを返す

    Returns:
        シナリオ名のリスト（例: ["scenario01", "scenario02", ...]）
    """
    scenarios = []
    for item in FIXTURE_BASE.iterdir():
        if item.is_dir() and item.name.startswith("scenario"):
            scenarios.append(item.name)
    return sorted(scenarios)


def cleanup_work_dir(work_dir: Path) -> None:
    """作業ディレクトリを削除

    Args:
        work_dir: 削除する作業ディレクトリパス
    """
    if work_dir.exists():
        shutil.rmtree(work_dir, ignore_errors=True)


def get_expected_dir(scenario_name: str) -> Path:
    """期待結果（Gold Master）ディレクトリのパスを返す

    Args:
        scenario_name: シナリオ名（例: "scenario01"）

    Returns:
        期待結果ディレクトリパス（シナリオと同じディレクトリ）

    Note:
        Gold Masterファイルは入力ファイルと同じディレクトリに
        "_expected" サフィックスをつけて配置する
        （例: システム機能設計書_サンプル_S01_expected.xlsx）
    """
    return FIXTURE_BASE / scenario_name


def get_expected_file_path(input_file_path: Path) -> Path:
    """入力ファイルに対応するGold Masterファイルのパスを返す

    Args:
        input_file_path: 入力ファイルパス

    Returns:
        Gold Masterファイルパス（_expected サフィックス付き）

    Example:
        >>> get_expected_file_path(Path("scenario01/design_S01.xlsx"))
        Path("scenario01/design_S01_expected.xlsx")
    """
    stem = input_file_path.stem  # 拡張子を除いたファイル名
    suffix = input_file_path.suffix  # 拡張子
    return input_file_path.parent / f"{stem}_expected{suffix}"
