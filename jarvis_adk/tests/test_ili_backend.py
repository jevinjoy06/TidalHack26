"""Verify ILI backend: alignment, matching, growth calculations with actual data."""

from pathlib import Path

# Project root (parent of jarvis_adk)
PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
ILIData_PATH = PROJECT_ROOT / "ILIDataV2.xlsx"


def test_backend():
    from jarvis_agent.tools.ili_processing import ILIDataset, reset_dataset, get_dataset

    reset_dataset()
    ds = get_dataset()

    # Step 1: Load
    assert ILIData_PATH.exists(), f"Data file not found: {ILIData_PATH}"
    load_result = ds.load(str(ILIData_PATH))
    assert "runs" in load_result
    assert "pipeline_length_ft" in load_result
    assert load_result["pipeline_length_ft"] > 0
    runs = load_result["runs"]
    assert len(runs) >= 2, "Need at least 2 runs"
    for year, run_info in runs.items():
        assert "total_features" in run_info
        assert "reference_points" in run_info
        assert "anomalies" in run_info
    print("[OK] Step 1: Load - runs loaded, pipeline length and run stats present")

    # Step 2 & 3: Align reference points and correction functions
    align_result = ds.align_welds()
    assert "weld_alignment" in align_result
    if "error" in align_result:
        raise AssertionError(f"Alignment error: {align_result['error']}")
    weld_align = align_result["weld_alignment"]
    assert len(weld_align) >= 1
    for pair_info in weld_align:
        assert "pair" in pair_info
        assert "matched" in pair_info
        assert "avg_offset_ft" in pair_info
    assert len(ds.correction_funcs) >= 1, "Expected at least one correction function"
    print("[OK] Step 2 & 3: Align welds and correction functions built")

    # Step 4: Match anomalies
    match_result = ds.match_anomalies()
    assert isinstance(match_result, dict)
    for pair_key, stats in match_result.items():
        assert "matched" in stats
        assert "new_in_later_run" in stats
        assert "missing_from_earlier_run" in stats
        assert "high_confidence" in stats
        assert "medium_confidence" in stats
        assert "low_confidence" in stats
    print("[OK] Step 4: Match anomalies - counts and confidence levels present")

    # Step 5: Growth rates
    growth_result = ds.calculate_growth()
    assert isinstance(growth_result, dict)
    for pair_key, stats in growth_result.items():
        assert "total_matched" in stats
        assert "critical_count" in stats
        assert "high_count" in stats
        assert "moderate_count" in stats
        assert "normal_count" in stats
    top = ds.get_top_growth(top_n=5)
    assert isinstance(top, list)
    print("[OK] Step 5: Growth rates and severity counts present")

    # Step 6: Exceptions (new, missing, uncertain)
    for (y1, y2), matches_df in ds.matches.items():
        pair_key = f"{y1}->{y2}"
        mr = match_result[pair_key]
        assert "new_in_later_run" in mr
        assert "missing_from_earlier_run" in mr
        assert "low_confidence" in mr
        assert mr["new_in_later_run"] >= 0
        assert mr["missing_from_earlier_run"] >= 0
        assert mr["low_confidence"] >= 0
        # New = unmatched in later run; Missing = unmatched in earlier run; Low = uncertain matches
    print("[OK] Step 6: Exception flagging (new, missing, uncertain/low) verified")

    # Sanity: growth formula (depth)
    for (y1, y2), growth_df in ds.growth.items():
        if growth_df.empty:
            continue
        row = growth_df.iloc[0]
        d1, d2 = row.get("y1_depth_pct"), row.get("y2_depth_pct")
        gap = row.get("years_between")
        depth_growth = row.get("depth_growth_pct_yr")
        if d1 is not None and d2 is not None and gap and not (d1 != d1):  # not NaN
            expected = (float(d2) - float(d1)) / gap
            assert abs((depth_growth or 0) - expected) < 0.001, f"Depth growth formula mismatch: {depth_growth} vs {expected}"
    print("[OK] Growth formula (Depth_Run2 - Depth_Run1) / Years verified")

    print("\nAll backend verification checks passed.")


if __name__ == "__main__":
    test_backend()
