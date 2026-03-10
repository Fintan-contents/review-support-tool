"""自動テストランナー（pytest アダプタ）

test/auto/ 配下のシナリオを pytest で自動実行する。
scenario_runner のコアロジックを使用し、Gold Master 比較の結果を
pytest の PASS/FAIL で報告する。

実行方法:
  python -m pytest scripts/auto_test_runner.py -v --tb=short
  python -m pytest scripts/auto_test_runner.py::TestScenarioGoldMaster::test_scenario_gold_master[scenario01] -v
"""
import pytest
from pathlib import Path

from scenario_runner import run_scenario, evaluate_scenario, TEMP_DIR


AUTO_DIR = Path(__file__).parent.parent / "auto"


def discover_scenarios() -> list[Path]:
    """test/auto/ 配下の scenarioXX ディレクトリを検出"""
    return sorted(d for d in AUTO_DIR.glob("scenario*") if d.is_dir())


class TestScenarioGoldMaster:
    """全シナリオの Gold Master 比較テスト"""

    @pytest.mark.parametrize("scenario_dir", discover_scenarios(), ids=lambda s: s.name)
    @pytest.mark.vba
    def test_scenario_gold_master(self, scenario_dir):
        """シナリオの Gold Master 比較テスト

        1. scenario_runner.run_scenario() で VBA を実行
        2. scenario_runner.evaluate_scenario() で結果を評価
        3. エラーがあれば pytest.fail() で報告
        """
        scenario_name = scenario_dir.name
        print(f"\n{'='*60}")
        print(f"Testing scenario: {scenario_name}")
        print(f"{'='*60}")

        try:
            work_dir, config = run_scenario(scenario_dir)
            errors = evaluate_scenario(work_dir, scenario_dir, config)
        except Exception as e:
            pytest.fail(str(e))

        if errors:
            pytest.fail("\n\n".join(errors))

        print(f"[{scenario_name}] ✓ All assertions passed")


@pytest.fixture(scope="session", autouse=True)
def print_scenario_summary():
    """テスト実行前にシナリオ一覧を表示"""
    scenarios = discover_scenarios()
    print("\n" + "=" * 60)
    print("Discovered Test Scenarios:")
    print("=" * 60)
    for s in scenarios:
        print(f"  {s.name}")
    print("=" * 60 + "\n")
    print(f"Actual outputs will be saved to: {TEMP_DIR}")
    print()
