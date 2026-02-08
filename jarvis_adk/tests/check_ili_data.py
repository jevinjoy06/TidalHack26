"""Inspect ILIDataV2.xlsx: verify required columns and reference points."""

from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
ILIData_PATH = PROJECT_ROOT / "ILIDataV2.xlsx"


def check_data():
    import pandas as pd
    from jarvis_agent.tools.ili_processing import (
        _YEAR_COL_MAPS,
        _build_rename_map,
        _is_reference,
        _is_anomaly,
        get_dataset,
        reset_dataset,
    )

    assert ILIData_PATH.exists(), f"Data file not found: {ILIData_PATH}"
    xls = pd.ExcelFile(ILIData_PATH)
    assert "Summary" in xls.sheet_names
    for year in [2007, 2015, 2022]:
        sheet = str(year)
        assert sheet in xls.sheet_names, f"Missing sheet {sheet}"
        df = pd.read_excel(xls, sheet)
        col_map = _YEAR_COL_MAPS.get(year, {})
        rename = _build_rename_map(df.columns, col_map)
        required = ["joint_number", "log_dist_ft", "event"]
        for r in required:
            assert r in rename.values(), f"{year}: missing column mapping for {r}"
        df = df.rename(columns=rename)
        refs = df[df["event"].apply(_is_reference)]
        anoms = df[df["event"].apply(_is_anomaly)]
        print(f"[OK] {year}: rows={len(df)}, reference_points={len(refs)}, anomalies={len(anoms)}")

    reset_dataset()
    ds = get_dataset()
    load_result = ds.load(str(ILIData_PATH))
    assert load_result["pipeline_length_ft"] > 0
    for year, info in load_result["runs"].items():
        assert info["reference_points"] > 0, f"{year}: no reference points"
        assert info["anomalies"] > 0, f"{year}: no anomalies"
    print("[OK] Load result: pipeline length and run stats valid")
    print("Data check complete.")


if __name__ == "__main__":
    check_data()
