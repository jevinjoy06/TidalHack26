"""Verify ILI API endpoints return expected responses."""

from pathlib import Path
from urllib.parse import quote

from fastapi.testclient import TestClient

PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
ILIData_PATH = PROJECT_ROOT / "ILIDataV2.xlsx"


def test_api_endpoints():
    from ili_api import app
    client = TestClient(app)
    # URL-encode path for query param (Windows backslashes, etc.)
    data_path = quote(str(ILIData_PATH), safe="")

    # Reset and load via query param
    r = client.get(f"/ili/load?file_path={data_path}")
    assert r.status_code == 200, r.text
    body = r.json()
    assert "runs" in body
    assert "pipeline_length_ft" in body
    assert body["pipeline_length_ft"] > 0
    print("[OK] GET /ili/load")

    r = client.get("/ili/summary")
    assert r.status_code == 200
    body = r.json()
    assert "runs_loaded" in body
    print("[OK] GET /ili/summary")

    r = client.get("/ili/align")
    assert r.status_code == 200
    body = r.json()
    assert "weld_alignment" in body
    assert "error" not in body
    print("[OK] GET /ili/align")

    r = client.get("/ili/match")
    assert r.status_code == 200
    body = r.json()
    assert isinstance(body, dict)
    for k, v in body.items():
        assert "matched" in v
        assert "new_in_later_run" in v
        assert "missing_from_earlier_run" in v
    print("[OK] GET /ili/match")

    r = client.get("/ili/growth?top_n=5")
    assert r.status_code == 200
    body = r.json()
    assert "statistics" in body
    assert "top_growing" in body
    print("[OK] GET /ili/growth")

    r = client.get("/ili/alignment-data")
    assert r.status_code == 200
    body = r.json()
    assert "weld_matches" in body
    assert "corrections" in body
    print("[OK] GET /ili/alignment-data")

    r = client.get("/ili/matches/2015->2022?limit=10&offset=0")
    assert r.status_code == 200
    body = r.json()
    assert isinstance(body, list)
    print("[OK] GET /ili/matches/{pair}")

    r = client.get("/ili/profile/2022")
    assert r.status_code == 200
    body = r.json()
    assert isinstance(body, list)
    print("[OK] GET /ili/profile/{year}")

    # run-all: same as load+align+match+growth in one call; structure verified by steps above
    r = client.get("/ili/run-all")
    assert r.status_code == 200, r.text
    body = r.json()
    assert "load" in body and "alignment" in body and "matching" in body
    assert "growth" in body and "top_growing" in body and "summary" in body
    print("[OK] GET /ili/run-all")

    print("\nAll API endpoint checks passed.")


def test_api_endpoints_fast():
    """Fast smoke test: load, summary, align, alignment-data only (no match/growth)."""
    from ili_api import app
    client = TestClient(app)
    data_path = quote(str(ILIData_PATH), safe="")
    for path, key in [
        (f"/ili/load?file_path={data_path}", "runs"),
        ("/ili/summary", "runs_loaded"),
        ("/ili/align", "weld_alignment"),
        ("/ili/alignment-data", "weld_matches"),
    ]:
        r = client.get(path)
        assert r.status_code == 200, f"{path}: {r.status_code}"
        assert key in r.json(), f"{path}: missing {key}"
    print("Fast API smoke test passed.")


if __name__ == "__main__":
    import sys
    try:
        test_api_endpoints_fast()
        print("Running full endpoint test (load->align->match->growth->run-all)...")
        test_api_endpoints()
    except Exception as e:
        print(str(e), file=sys.stderr)
        raise
