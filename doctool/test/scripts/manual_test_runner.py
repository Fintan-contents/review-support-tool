"""手動テストランナー

手動操作が必要なシナリオを対話的に実行する。
scenario_runner のコアロジックを使用し、ユーザー操作待ちのプロンプトを提供する。

実行方法:
  python scripts/manual_test_runner.py                       # 全シナリオ実行
  python scripts/manual_test_runner.py scenario05            # 特定シナリオのみ
  python scripts/manual_test_runner.py scenario05 scenario06 # 複数シナリオ指定
"""
import sys
from pathlib import Path

from helpers.config_loader import load_scenario_config
from scenario_runner import run_scenario, evaluate_scenario


MANUAL_BASE = Path(__file__).parent.parent / "manual"


def discover_manual_scenarios(filter_names: list[str] = None) -> list[Path]:
    """manual/ 配下のシナリオディレクトリを検出"""
    scenarios = sorted(d for d in MANUAL_BASE.glob("scenario*") if d.is_dir())
    if filter_names:
        scenarios = [s for s in scenarios if s.name in filter_names]
    return scenarios


def _print_sep(char: str = "=", width: int = 60):
    print(char * width)


def _print_scenario_header(scenario_name: str, config: dict):
    print()
    _print_sep()
    print(f"手動テスト: {scenario_name}")
    print(f"観点: {config.get('viewpoint', '(不明)')}")
    _print_sep()
    instructions = config.get("instructions", [])
    if instructions:
        print("\n操作手順:")
        for i, step in enumerate(instructions, 1):
            print(f"  {i}. {step}")
    print()


def run_manual_tests(filter_names: list[str] = None):
    """手動テストを順次実行する"""
    scenarios = discover_manual_scenarios(filter_names)

    if not scenarios:
        if filter_names:
            print(f"シナリオ {filter_names} が見つかりません")
            print(f"利用可能なシナリオ: {[s.name for s in discover_manual_scenarios()]}")
        else:
            print("手動テストシナリオが見つかりません")
        return

    print()
    _print_sep()
    print(f"手動テストシナリオ: {len(scenarios)} 件")
    for s in scenarios:
        cfg = load_scenario_config(str(s))
        print(f"  - {s.name}: {cfg.get('viewpoint', '')}")
    print("実行後のファイルは temp_dir/ に保存されます")
    _print_sep()

    results = []

    for i, scenario_src_dir in enumerate(scenarios):
        scenario_name = scenario_src_dir.name
        config = load_scenario_config(str(scenario_src_dir))

        _print_scenario_header(scenario_name, config)
        input("準備ができたら Enter を押してください...")

        try:
            work_dir, config = run_scenario(scenario_src_dir)
            errors = evaluate_scenario(work_dir, scenario_src_dir, config)

            if errors:
                print(f"\n[{scenario_name}] ✗ FAIL")
                for e in errors:
                    print(f"  {e}")
                results.append((scenario_name, False))
            else:
                print(f"\n[{scenario_name}] ✓ PASS")
                results.append((scenario_name, True))

        except Exception as e:
            print(f"\n[{scenario_name}] ✗ ERROR: {e}")
            results.append((scenario_name, False))

        if i < len(scenarios) - 1:
            print()
            input("Excel が完全に終了したことを確認して Enter を押してください（次のシナリオへ）...")

    # サマリー
    print()
    _print_sep()
    print("テスト結果サマリー")
    _print_sep()
    for name, passed in results:
        status = "✓ PASS" if passed else "✗ FAIL"
        print(f"  {status}: {name}")
    passed_count = sum(1 for _, p in results if p)
    print(f"\n合計: {passed_count}/{len(results)} PASS")
    _print_sep()


if __name__ == "__main__":
    filter_names = sys.argv[1:] if len(sys.argv) > 1 else None
    run_manual_tests(filter_names)
