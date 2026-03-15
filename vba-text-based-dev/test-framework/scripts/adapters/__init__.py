"""テストフレームワーク汎用アダプタ層

汎用テストエンジン（ExecutionOrchestrator / ExcelPlatform）と
ツール固有ロジックを分離するためのインターフェース定義。

主要コンポーネント:
  - ComparisonConfig: Gold Master 比較の項目制御設定
  - ToolAdapter: ツール固有処理の Protocol 定義
  - BaseToolAdapter: Protocol 実装のデフォルト基底クラス
  - load_adapter(): tool_config.yaml からアダプタを動的ロード
"""
from __future__ import annotations

import importlib
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, List, Optional, Protocol, runtime_checkable


# ---------------------------------------------------------------------------
# ComparisonConfig
# ---------------------------------------------------------------------------

@dataclass
class ComparisonConfig:
    """Gold Master 比較で検証する項目を制御するデータクラス。

    デフォルトはすべて True（後方互換）。
    values と sheet_names はイミュータブル（無効化不可）。

    Attributes:
        values: セル値の比較（無効化不可）
        formulas: 数式の比較
        comments: コメント（メモ）の比較
        borders: 罫線の比較
        column_widths: 明示設定された列幅の比較
        print_area: 印刷範囲の比較
        fill_colors: 背景色（塗りつぶし）の比較
    """
    values: bool = True
    formulas: bool = True
    comments: bool = True
    borders: bool = True
    column_widths: bool = True
    print_area: bool = True
    fill_colors: bool = True

    # 無効化不可のフィールド（values は常に比較対象）
    _IMMUTABLE_FIELDS: frozenset = frozenset({"values"})

    def merge(self, override: Dict[str, Any]) -> ComparisonConfig:
        """override dict をマージした新しい ComparisonConfig を返す。

        _IMMUTABLE_FIELDS に含まれるフィールドは override で False にできない。

        Args:
            override: 上書きするフィールドと値の dict
                例: {"print_area": False, "fill_colors": False}

        Returns:
            マージ後の ComparisonConfig（self は変更しない）
        """
        merged = ComparisonConfig(
            values=self.values,
            formulas=self.formulas,
            comments=self.comments,
            borders=self.borders,
            column_widths=self.column_widths,
            print_area=self.print_area,
            fill_colors=self.fill_colors,
        )
        for key, val in override.items():
            if key in ComparisonConfig._IMMUTABLE_FIELDS:
                continue  # イミュータブル項目は無視
            if hasattr(merged, key) and not key.startswith("_"):
                setattr(merged, key, bool(val))
        return merged


# ---------------------------------------------------------------------------
# ToolAdapter Protocol
# ---------------------------------------------------------------------------

@runtime_checkable
class ToolAdapter(Protocol):
    """ツール固有の処理を汎用テストエンジンから分離するための Protocol。

    各メソッドは ExecutionOrchestrator から呼び出される。
    ツールごとに本 Protocol を実装したクラスを作成する。
    """

    def get_macro_entry_point(self) -> str:
        """メインマクロのパスを返す。

        Returns:
            例: "Sheet1.CmdGen_Click_Core"
        """
        ...

    def apply_setup(
        self,
        scenario_name: str,
        xlsm_wb: Any,
        setup: Dict[str, Any],
        work_dir: Path,
    ) -> None:
        """xlsm の事前設定を適用する。

        config.yaml の setup セクションに対応するツール固有処理を行う。

        Args:
            scenario_name: ログ用シナリオ名
            xlsm_wb: xlwings Workbook オブジェクト
            setup: config.yaml の setup dict
            work_dir: テスト作業ディレクトリ
        """
        ...

    def pre_macro_hook(
        self,
        scenario_name: str,
        xlsm_wb: Any,
        step: Dict[str, Any],
        work_dir: Path,
    ) -> None:
        """マクロ実行前の処理（ステップ固有の準備）。

        Args:
            scenario_name: ログ用シナリオ名
            xlsm_wb: xlwings Workbook オブジェクト
            step: config.yaml の step dict
            work_dir: テスト作業ディレクトリ
        """
        ...

    def post_macro_hook(
        self,
        scenario_name: str,
        xlsm_wb: Any,
        step: Dict[str, Any],
        work_dir: Path,
    ) -> None:
        """マクロ実行後の処理（ログ取得等）。

        Args:
            scenario_name: ログ用シナリオ名
            xlsm_wb: xlwings Workbook オブジェクト
            step: config.yaml の step dict
            work_dir: テスト作業ディレクトリ
        """
        ...

    def get_default_comparison(self) -> ComparisonConfig:
        """このツールのデフォルト比較設定を返す。

        Returns:
            ComparisonConfig: ツールに適したデフォルト比較設定
        """
        ...

    def evaluate_custom_assertions(
        self,
        work_dir: Path,
        assertions: List[Dict[str, Any]],
    ) -> List[str]:
        """ツール固有のアサーションを評価する。

        config.yaml の template_assertions 等、ツール固有の検証を行う。

        Args:
            work_dir: VBA 実行後のファイルが格納されたディレクトリ
            assertions: ツール固有アサーションのリスト

        Returns:
            エラーメッセージのリスト（空なら全アサーション通過）
        """
        ...

    def execute_steps(
        self,
        scenario_name: str,
        xlsm_wb: Any,
        steps: List[Dict[str, Any]],
        test_mode: bool,
        work_dir: Path,
        platform: Any,
    ) -> None:
        """シナリオの全ステップを実行する（ツール固有のアクション実装）。

        ExecutionOrchestrator._execute_vba から呼ばれる。
        ツール固有のアクション（extract / delete_comments 等）の実行ロジックを実装する。

        Args:
            scenario_name: ログ用シナリオ名
            xlsm_wb: xlwings Workbook オブジェクト（xlsm）
            steps: config.yaml の steps リスト
            test_mode: testMode フラグ（True=自動、False=手動）
            work_dir: テスト作業ディレクトリ
            platform: ExcelPlatform インスタンス（マクロ実行リトライ等に使用）
        """
        ...

    def teardown(self) -> None:
        """テスト後のクリーンアップ処理。"""
        ...


# ---------------------------------------------------------------------------
# BaseToolAdapter
# ---------------------------------------------------------------------------

class BaseToolAdapter:
    """ToolAdapter Protocol のデフォルト実装基底クラス。

    各メソッドは no-op / デフォルト値を返す。
    ツール固有アダプタはこのクラスを継承し、必要なメソッドのみオーバーライドする。
    """

    def get_macro_entry_point(self) -> str:
        raise NotImplementedError(
            f"{self.__class__.__name__} は get_macro_entry_point() を実装する必要があります"
        )

    def apply_setup(
        self,
        scenario_name: str,
        xlsm_wb: Any,
        setup: Dict[str, Any],
        work_dir: Path,
    ) -> None:
        pass  # デフォルト: 何もしない

    def pre_macro_hook(
        self,
        scenario_name: str,
        xlsm_wb: Any,
        step: Dict[str, Any],
        work_dir: Path,
    ) -> None:
        pass  # デフォルト: 何もしない

    def post_macro_hook(
        self,
        scenario_name: str,
        xlsm_wb: Any,
        step: Dict[str, Any],
        work_dir: Path,
    ) -> None:
        pass  # デフォルト: 何もしない

    def get_default_comparison(self) -> ComparisonConfig:
        return ComparisonConfig()  # 全項目デフォルト ON

    def evaluate_custom_assertions(
        self,
        work_dir: Path,
        assertions: List[Dict[str, Any]],
    ) -> List[str]:
        return []  # デフォルト: アサーションなし

    def execute_steps(
        self,
        scenario_name: str,
        xlsm_wb: Any,
        steps: List[Dict[str, Any]],
        test_mode: bool,
        work_dir: Path,
        platform: Any,
    ) -> None:
        raise NotImplementedError(
            f"{self.__class__.__name__} は execute_steps() を実装する必要があります"
        )

    def teardown(self) -> None:
        pass  # デフォルト: 何もしない


# ---------------------------------------------------------------------------
# load_adapter ユーティリティ
# ---------------------------------------------------------------------------

def load_adapter(tool_config: Dict[str, Any]) -> BaseToolAdapter:
    """tool_config.yaml の adapter キーからアダプタインスタンスを動的生成する。

    tool_config.yaml の例:
        adapter:
          module: "adapters.doctool_adapter"
          class: "DoctoolAdapter"

    adapter キーが未指定の場合は BaseToolAdapter を返す（汎用フォールバック）。

    Args:
        tool_config: tool_config.yaml を読み込んだ dict

    Returns:
        ToolAdapter を実装したインスタンス

    Raises:
        ImportError: 指定モジュールが見つからない場合
        AttributeError: 指定クラスがモジュールに存在しない場合
    """
    adapter_cfg = tool_config.get("adapter", {})
    module_path = adapter_cfg.get("module")
    class_name = adapter_cfg.get("class")

    if not module_path or not class_name:
        return BaseToolAdapter()

    module = importlib.import_module(module_path)
    cls = getattr(module, class_name)
    return cls()
