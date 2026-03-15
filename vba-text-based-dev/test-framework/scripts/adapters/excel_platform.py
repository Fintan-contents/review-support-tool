"""Excel COM 操作基盤クラス

Excel プロセスのライフサイクル管理（起動・クリーンアップ）とマクロ実行
（COM エラー時リトライ付き）を提供する薄いラッパークラス。

重要: このクラスは scenario_runner.py から移設した既存の COM 呼び出し順序を
完全に維持する。順序変更は Excel の状態管理に致命的な影響を与えるため、
ロジックを追加せず、移設のみ行っている。

xlwings / pywintypes は Windows 専用ライブラリのため、
メソッド内で遅延インポートする（WSL2 での syntax チェックを可能にするため）。
"""
from __future__ import annotations

from pathlib import Path
from typing import List, Tuple


class ExcelPlatform:
    """Excel COM 操作の薄いラッパークラス。

    Excel プロセスのライフサイクル（起動・ファイルopen・保存・クリーンアップ）と
    VBA マクロのリトライ実行を管理する。ツール固有のロジックは含まない。
    """

    def launch(self, scenario_name: str, visible: bool):
        """Excel を起動し、デフォルトブックを閉じて App オブジェクトを返す。

        Args:
            scenario_name: ログ用シナリオ名
            visible: Excel ウィンドウを表示するか

        Returns:
            xw.App: 起動した Excel アプリケーションオブジェクト
        """
        import xlwings as xw  # Windows専用: メソッド内で遅延インポート

        print(f"[{scenario_name}] Excel を起動中... (visible={visible})")
        app = xw.App(visible=visible)

        # Excel 起動時に自動作成されるデフォルトブック（Book1 等）を閉じる
        for book in list(app.books):
            try:
                book.close()
            except Exception:
                pass

        return app

    def run_macro_with_retry(
        self,
        scenario_name: str,
        macro,
        test_mode: bool,
        max_retries: int = 3,
    ) -> None:
        """VBA マクロを COM エラー時にリトライ付きで実行する。

        エラーコード 0x80010100 (RPC_E_SERVERCALL_ISBUSY) は Excel が COM メッセージポンプに
        応答できない状態を示す。一時的なビジー状態のため、待機後に再試行することで回復できる。

        Args:
            scenario_name: ログ用シナリオ名
            macro: xlwings マクロオブジェクト
            test_mode: テストモードフラグ（マクロに渡す引数）
            max_retries: 最大リトライ回数
        """
        import pywintypes  # Windows専用: メソッド内で遅延インポート
        import time

        COM_E_SERVER_ISBUSY = -2147417856  # 0x80010100
        retry_wait_seconds = 4

        for attempt in range(1, max_retries + 2):
            try:
                macro(test_mode)
                return
            except pywintypes.com_error as e:
                hresult = e.hresult if hasattr(e, "hresult") else (e.args[0] if e.args else None)
                if hresult == COM_E_SERVER_ISBUSY and attempt <= max_retries:
                    print(
                        f"[{scenario_name}]   COMエラー (0x80010100: サーバービジー)。"
                        f"{retry_wait_seconds}秒後にリトライ ({attempt}/{max_retries})..."
                    )
                    time.sleep(retry_wait_seconds)
                else:
                    raise

    def save_all(
        self,
        scenario_name: str,
        app,
        open_wbs: List[Tuple[str, object]],
        xlsm_wb,
        xlsm_name: str,
    ) -> None:
        """すべての開いているブックを保存する。

        VBA が自分で開いたファイル（skip_open_files で除外されたもの）も保存する。

        Args:
            scenario_name: ログ用シナリオ名
            app: xlwings App オブジェクト
            open_wbs: Python から開いたブックのリスト [(名前, wb), ...]
            xlsm_wb: xlsm ワークブックオブジェクト
            xlsm_name: xlsm ファイル名（VBA 開きファイル判定に使用）
        """
        python_opened_names = {wb.name for _, wb in open_wbs} | {xlsm_name}
        for _, wb in open_wbs:
            try:
                wb.save()
            except Exception as e:
                print(f"[{scenario_name}]   保存警告: {e}")

        # VBA が自分で開いたファイルも保存する
        for book in app.books:
            if book.name not in python_opened_names:
                try:
                    book.save()
                    print(f"[{scenario_name}]   VBA開きファイル保存: {book.name}")
                except Exception as e:
                    print(f"[{scenario_name}]   保存警告 (VBA-opened): {e}")

        xlsm_wb.save()
        print(f"[{scenario_name}] Saved → temp_dir/{scenario_name}/")

    def cleanup(
        self,
        scenario_name: str,
        app,
        open_wbs: List[Tuple[str, object]],
        xlsm_wb,
    ) -> None:
        """Excel プロセスをクリーンアップする。

        COM オブジェクトへの参照を明示的に None で破棄してから app.quit() を呼ぶ。
        参照を残したまま quit すると GC 時に死んだサーバーへ接続しようとして
        'Windows fatal exception: code 0x800706ba' (RPC_S_SERVER_UNAVAILABLE) が発生する。

        Args:
            scenario_name: ログ用シナリオ名
            app: xlwings App オブジェクト（None 可）
            open_wbs: Python から開いたブックのリスト（cleanup で clear される）
            xlsm_wb: xlsm ワークブックオブジェクト（None 可）
        """
        import gc
        import time

        for _, wb in open_wbs:
            try:
                wb.close()
            except Exception:
                pass
        open_wbs.clear()

        if xlsm_wb:
            try:
                xlsm_wb.close()
            except Exception:
                pass
            xlsm_wb = None  # noqa: F841 — COM参照を明示破棄

        gc.collect()  # close後・quit前にCOM参照を解放

        if app:
            try:
                app.quit()
            except Exception:
                pass
            app = None  # noqa: F841

        gc.collect()

        try:
            import psutil
            for i in range(10):
                if not any(
                    p.name().lower() == "excel.exe"
                    for p in psutil.process_iter(["name"])
                ):
                    print(f"[{scenario_name}] Excel 終了確認 ({i + 1}s)")
                    break
                time.sleep(1)
            else:
                print(f"[{scenario_name}] 警告: Excel が 10秒後も残留中")
        except Exception:
            pass
