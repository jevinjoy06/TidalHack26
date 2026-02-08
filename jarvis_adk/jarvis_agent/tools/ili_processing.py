"""Core ILI data alignment engine.

Ingests ILI Excel data (2007, 2015, 2022), normalises columns,
aligns reference points (girth welds), corrects odometer drift,
matches anomalies across runs, and computes corrosion growth rates.
"""

from __future__ import annotations

import math
from pathlib import Path
from typing import Any

import pandas as pd
import numpy as np
from scipy.interpolate import interp1d

# ---------------------------------------------------------------------------
# Column normalisation maps (each year → canonical name)
# ---------------------------------------------------------------------------

_COL_MAP_2007 = {
    "J. no.": "joint_number",
    "J. len [ft]": "joint_length_ft",
    "t [in]": "wall_thickness_in",
    "to u/s w. [ft]": "dist_to_us_weld_ft",
    "log dist. [ft]": "log_dist_ft",
    "Height [ft]": "elevation_ft",
    "event": "event",
    "depth [%]": "depth_pct",
    "length [in]": "length_in",
    "width [in]": "width_in",
    "o'clock": "oclock",
    "internal": "id_od",
    "comment": "comments",
    "P2 Burst / MOP": "burst_mop_ratio",
    "ID Reduction [%]": "id_reduction_pct",
}

_COL_MAP_2015 = {
    "J. no.": "joint_number",
    "J. len [ft]": "joint_length_ft",
    "Wt [in]": "wall_thickness_in",
    "to u/s w. [ft]": "dist_to_us_weld_ft",
    "to d/s w. [ft]": "dist_to_ds_weld_ft",
    "Log Dist. [ft]": "log_dist_ft",
    "Event Description": "event",
    "Depth [%]": "depth_pct",
    "Depth [in]": "depth_in",
    "Length [in]": "length_in",
    "Width [in]": "width_in",
    "O'clock": "oclock",
    "ID/OD": "id_od",
    "Comments": "comments",
    "Tool Velocity [ft/s]": "tool_velocity",
    "Elevation [ft]": "elevation_ft",
    "MOP [PSI]": "mop_psi",
    "SMYS [PSI]": "smys_psi",
    "Pdesign [PSI]": "pdesign_psi",
    "B31G Psafe [PSI]": "b31g_psafe_psi",
    "B31G Pburst [PSI]": "b31g_pburst_psi",
    "Mod B31G Psafe [PSI]": "mod_b31g_psafe_psi",
    "Mod B31G Pburst [PSI]": "mod_b31g_pburst_psi",
    "Effective Area Psafe [PSI]": "eff_area_psafe_psi",
    "Effective Area Pburst [PSI]": "eff_area_pburst_psi",
    "ERF": "erf",
    "RPR": "rpr",
    "OD Reduction [%]": "od_reduction_pct",
    "OD Reduction [in]": "od_reduction_in",
    "Anomalies per Joint": "anomalies_per_joint",
}

_COL_MAP_2022 = {
    "Joint Number": "joint_number",
    "Joint Length [ft]": "joint_length_ft",
    "WT [in]": "wall_thickness_in",
    "Distance to U/S GW [ft]": "dist_to_us_weld_ft",
    "Distance to D/S GW [ft]": "dist_to_ds_weld_ft",
    "ILI Wheel Count [ft.]": "log_dist_ft",
    "Event Description": "event",
    "Metal Loss Depth [%]": "depth_pct",
    "Metal Loss Depth [in]": "depth_in",
    "Metal Loss Depth + Tolerance [%]": "depth_plus_tol_pct",
    "Metal Loss Depth Tolerance [%] (includes seamless and HAZ and modified specs)": "depth_tol_pct",
    "Length [in]": "length_in",
    "Width [in]": "width_in",
    "O'clock [hh:mm]": "oclock",
    "ID/OD": "id_od",
    "Comments": "comments",
    "Anomalies per Joint": "anomalies_per_joint",
    "Elevation [ft]": "elevation_ft",
    "SMYS [PSI]": "smys_psi",
    "Pdesign [PSI]": "pdesign_psi",
    "Mod B31G Psafe [PSI]": "mod_b31g_psafe_psi",
    "Mod B31G Pburst [PSI]": "mod_b31g_pburst_psi",
    "Mod B31G Psafe Pressure with Tolerance [PSI]": "mod_b31g_psafe_tol_psi",
    "Mod B31G Pburst Pressure with Tolerance [PSI]": "mod_b31g_pburst_tol_psi",
    "Effective Area Psafe [PSI]": "eff_area_psafe_psi",
    "Effective Area Pburst [PSI]": "eff_area_pburst_psi",
    "ERF": "erf",
    "RPR": "rpr",
    "Dent Depth [%]": "dent_depth_pct",
    "Dent Depth [in]": "dent_depth_in",
    "Dimension Classification": "dimension_class",
    "Magnetization Level [kA/m] for MFL survey or Actual WT [in] for UT Survey": "magnetization",
    "Evaluation Pressure [PSI]": "eval_pressure_psi",
    "Pipe Diameter (O.D.) [in.]": "pipe_od_in",
    "Pipe Type": "pipe_type",
    "Tool": "tool",
    "Seam Position [hh:mm]": "seam_position",
    "Distance To Seam Weld [in]": "dist_to_seam_in",
    "Was anomaly sizing reviewed by analyst? [Y/N]": "sizing_reviewed",
    "Was anomaly sizing/dimensions manually changed? [Y/N]": "sizing_changed",
    "Is any part of the dent affecting the top of the pipe? [Y/N]": "dent_top_pipe",
    "Length Tolerance [in]": "length_tol_in",
    "Width Tolerance [in]": "width_tol_in",
}

_YEAR_COL_MAPS = {2007: _COL_MAP_2007, 2015: _COL_MAP_2015, 2022: _COL_MAP_2022}


def _normalize_col(name: str) -> str:
    """Collapse whitespace/newlines in column names for fuzzy matching."""
    import re
    return re.sub(r"\s+", " ", str(name)).strip()


def _build_rename_map(df_columns, col_map: dict) -> dict:
    """Build a rename dict matching actual df columns to canonical names.

    Handles Excel columns with embedded newlines and extra whitespace
    by comparing normalised (collapsed-whitespace) versions.
    """
    # Build lookup: normalised_key → canonical_name
    norm_lookup = {_normalize_col(k): v for k, v in col_map.items()}

    rename = {}
    for actual_col in df_columns:
        norm = _normalize_col(actual_col)
        if norm in norm_lookup:
            rename[actual_col] = norm_lookup[norm]
    return rename

# Event types that are reference / fixed points
_REFERENCE_EVENTS = {
    "girth weld", "girthweld", "bend", "field bend", "valve", "tee",
    "flange", "reducer", "casing", "tap", "attachment",
}

# Event types that are anomalies (defects)
_ANOMALY_EVENTS = {
    "metal loss", "cluster", "dent",
    "metal loss-manufacturing anomaly",
    "metal loss manufacturing",
    "seam weld manufacturing anomaly",
    "girth weld anomaly",
}


def _normalize_event(event: str) -> str:
    """Normalize event name: lowercase, collapse whitespace."""
    return " ".join(event.strip().lower().split())


def _is_reference(event: str) -> bool:
    ev = _normalize_event(event)
    return ev in _REFERENCE_EVENTS or ev.replace(" ", "") in {r.replace(" ", "") for r in _REFERENCE_EVENTS}


def _is_anomaly(event: str) -> bool:
    ev = _normalize_event(event)
    return any(a in ev for a in _ANOMALY_EVENTS)


def _is_metal_loss(event: str) -> bool:
    ev = _normalize_event(event)
    return "metal loss" in ev or "cluster" in ev


# ---------------------------------------------------------------------------
# Clock position helpers
# ---------------------------------------------------------------------------

def _parse_oclock(val) -> float | None:
    """Convert o'clock value to decimal hours (0-12)."""
    if val is None or (isinstance(val, float) and math.isnan(val)):
        return None
    s = str(val).strip()
    if not s:
        return None
    # Handle HH:MM format
    if ":" in s:
        parts = s.split(":")
        try:
            h = int(parts[0]) % 12
            m = int(parts[1]) / 60.0
            return h + m
        except (ValueError, IndexError):
            return None
    # Handle decimal format
    try:
        v = float(s)
        return v % 12.0
    except ValueError:
        return None


def _clock_distance(a: float, b: float) -> float:
    """Minimum angular distance between two clock positions (0-6 hours)."""
    diff = abs(a - b) % 12.0
    return min(diff, 12.0 - diff)


# ---------------------------------------------------------------------------
# Data ingestion
# ---------------------------------------------------------------------------

class ILIDataset:
    """Holds normalised ILI data for all runs."""

    def __init__(self):
        self.summary: pd.DataFrame | None = None
        self.runs: dict[int, pd.DataFrame] = {}   # year → DataFrame
        self.references: dict[int, pd.DataFrame] = {}
        self.anomalies: dict[int, pd.DataFrame] = {}
        self.aligned_welds: pd.DataFrame | None = None
        self.correction_funcs: dict[tuple[int, int], Any] = {}
        self.matches: dict[tuple[int, int], pd.DataFrame] = {}
        self.growth: dict[tuple[int, int], pd.DataFrame] = {}
        self._file_path: str | None = None

    def load(self, file_path: str) -> dict:
        """Load and normalise ILI Excel data. Returns summary dict."""
        self._file_path = file_path
        path = Path(file_path)
        if not path.exists():
            raise FileNotFoundError(f"ILI data file not found: {file_path}")

        xls = pd.ExcelFile(path)
        self.summary = pd.read_excel(xls, "Summary")

        result = {"pipeline_length_ft": 0, "runs": {}}

        for year in [2007, 2015, 2022]:
            sheet_name = str(year)
            if sheet_name not in xls.sheet_names:
                continue

            df = pd.read_excel(xls, sheet_name)
            col_map = _YEAR_COL_MAPS.get(year, {})

            # Fuzzy-rename columns (handles newlines/extra whitespace in Excel headers)
            rename = _build_rename_map(df.columns, col_map)
            df = df.rename(columns=rename)
            df["year"] = year

            # Parse o'clock to decimal
            if "oclock" in df.columns:
                df["oclock_decimal"] = df["oclock"].apply(_parse_oclock)

            self.runs[year] = df

            # Separate references and anomalies
            refs = df[df["event"].apply(_is_reference)].copy()
            anoms = df[df["event"].apply(_is_anomaly)].copy()
            self.references[year] = refs
            self.anomalies[year] = anoms

            max_dist = float(df["log_dist_ft"].max()) if "log_dist_ft" in df.columns else 0
            result["pipeline_length_ft"] = max(result["pipeline_length_ft"], max_dist)
            result["runs"][year] = {
                "total_features": len(df),
                "reference_points": len(refs),
                "anomalies": len(anoms),
                "girth_welds": int((refs["event"].str.lower().str.replace(" ", "").str.contains("girthweld")).sum()) if len(refs) > 0 else 0,
                "metal_loss": int(anoms["event"].apply(_is_metal_loss).sum()) if len(anoms) > 0 else 0,
                "max_distance_ft": round(max_dist, 1),
            }

        return result

    # ------------------------------------------------------------------
    # Phase 1: Align reference points (girth welds)
    # ------------------------------------------------------------------

    def align_welds(self) -> dict:
        """Match girth welds across runs and build correction functions."""
        years = sorted(self.runs.keys())
        if len(years) < 2:
            return {"error": "Need at least 2 runs to align"}

        all_matches = []

        for i in range(len(years) - 1):
            y1, y2 = years[i], years[i + 1]
            matches = self._match_welds(y1, y2)
            all_matches.append({
                "pair": f"{y1}->{y2}",
                "matched": len(matches),
                "avg_offset_ft": round(float(matches["offset"].mean()), 3) if len(matches) > 0 else 0,
                "max_offset_ft": round(float(matches["offset"].abs().max()), 3) if len(matches) > 0 else 0,
                "std_offset_ft": round(float(matches["offset"].std()), 3) if len(matches) > 0 else 0,
            })

            # Build piecewise correction function
            if len(matches) >= 2:
                self.correction_funcs[(y1, y2)] = interp1d(
                    matches["dist_y2"].values,
                    matches["dist_y1"].values,
                    kind="linear",
                    fill_value="extrapolate",
                    bounds_error=False,
                )

        # Also build direct 2007->2022 if we have both
        if (2007 in self.runs and 2022 in self.runs and
                2007 in self.references and 2022 in self.references):
            matches_direct = self._match_welds(2007, 2022)
            all_matches.append({
                "pair": "2007->2022",
                "matched": len(matches_direct),
                "avg_offset_ft": round(float(matches_direct["offset"].mean()), 3) if len(matches_direct) > 0 else 0,
                "max_offset_ft": round(float(matches_direct["offset"].abs().max()), 3) if len(matches_direct) > 0 else 0,
            })
            if len(matches_direct) >= 2:
                self.correction_funcs[(2007, 2022)] = interp1d(
                    matches_direct["dist_y2"].values,
                    matches_direct["dist_y1"].values,
                    kind="linear",
                    fill_value="extrapolate",
                    bounds_error=False,
                )

        return {"weld_alignment": all_matches}

    def _match_welds(self, y1: int, y2: int) -> pd.DataFrame:
        """Match girth welds between two runs by joint number."""
        if y1 not in self.references or y2 not in self.references:
            return pd.DataFrame()
        ref1 = self.references[y1]
        ref2 = self.references[y2]

        welds1 = ref1[ref1["event"].str.lower().str.replace(" ", "").str.contains("girthweld")].copy()
        welds2 = ref2[ref2["event"].str.lower().str.replace(" ", "").str.contains("girthweld")].copy()

        # Cast joint_number to int to avoid int/float merge warning
        w1 = welds1[["joint_number", "log_dist_ft"]].dropna(subset=["joint_number"]).copy()
        w2 = welds2[["joint_number", "log_dist_ft"]].dropna(subset=["joint_number"]).copy()
        w1["joint_number"] = w1["joint_number"].astype(int)
        w2["joint_number"] = w2["joint_number"].astype(int)

        # Match by joint number
        merged = pd.merge(
            w1, w2,
            on="joint_number",
            suffixes=("_y1", "_y2"),
            how="inner",
        )
        merged = merged.rename(columns={
            "log_dist_ft_y1": "dist_y1",
            "log_dist_ft_y2": "dist_y2",
        })
        merged["offset"] = merged["dist_y2"] - merged["dist_y1"]
        merged = merged.sort_values("dist_y1").reset_index(drop=True)

        self.aligned_welds = merged
        return merged

    # ------------------------------------------------------------------
    # Phase 2: Match anomalies
    # ------------------------------------------------------------------

    def match_anomalies(
        self,
        distance_tol: float = 3.0,
        clock_tol: float = 1.5,
        depth_weight: float = 0.3,
        dist_weight: float = 0.4,
        clock_weight: float = 0.3,
    ) -> dict:
        """Match anomalies across consecutive runs."""
        years = sorted(self.runs.keys())
        results = {}

        for i in range(len(years) - 1):
            y1, y2 = years[i], years[i + 1]
            pair_result = self._match_anomaly_pair(
                y1, y2, distance_tol, clock_tol,
                depth_weight, dist_weight, clock_weight,
            )
            results[f"{y1}->{y2}"] = pair_result

        # Direct 2007->2022
        if 2007 in self.runs and 2022 in self.runs:
            pair_result = self._match_anomaly_pair(
                2007, 2022, distance_tol, clock_tol,
                depth_weight, dist_weight, clock_weight,
            )
            results["2007->2022"] = pair_result

        return results

    def _match_anomaly_pair(
        self, y1: int, y2: int,
        distance_tol: float, clock_tol: float,
        depth_weight: float, dist_weight: float, clock_weight: float,
    ) -> dict:
        """Match anomalies between two specific runs."""
        anoms1 = self.anomalies[y1].copy()
        anoms2 = self.anomalies[y2].copy()

        # Filter to metal-loss type only
        ml1 = anoms1[anoms1["event"].apply(_is_metal_loss)].copy()
        ml2 = anoms2[anoms2["event"].apply(_is_metal_loss)].copy()

        # Apply distance correction if available
        corr_key = (y1, y2)
        if corr_key in self.correction_funcs:
            corr_func = self.correction_funcs[corr_key]
            ml2["corrected_dist"] = corr_func(ml2["log_dist_ft"].values)
        else:
            ml2["corrected_dist"] = ml2["log_dist_ft"]

        matched_pairs = []
        used_y1 = set()
        used_y2 = set()

        # For each anomaly in y2, find best match in y1
        for idx2, row2 in ml2.iterrows():
            corr_dist = row2["corrected_dist"]
            clock2 = row2.get("oclock_decimal")

            best_score = -1
            best_idx1 = None
            candidates = 0

            for idx1, row1 in ml1.iterrows():
                if idx1 in used_y1:
                    continue

                dist1 = row1["log_dist_ft"]
                dist_diff = abs(corr_dist - dist1)
                if dist_diff > distance_tol:
                    continue

                # Clock check
                clock1 = row1.get("oclock_decimal")
                if clock1 is not None and clock2 is not None:
                    clock_diff = _clock_distance(clock1, clock2)
                    if clock_diff > clock_tol:
                        continue
                else:
                    clock_diff = 0  # No clock data, don't penalize

                candidates += 1

                # Compute similarity score (0-1, higher = better match)
                dist_score = 1.0 - (dist_diff / distance_tol)

                clock_score = 1.0 - (clock_diff / clock_tol) if (clock1 is not None and clock2 is not None) else 0.5

                depth1 = row1.get("depth_pct")
                depth2 = row2.get("depth_pct")
                if pd.notna(depth1) and pd.notna(depth2) and depth1 > 0:
                    # Depth should grow or stay same; penalize shrinkage heavily
                    depth_ratio = depth2 / depth1
                    if depth_ratio >= 1.0:
                        depth_score = max(0, 1.0 - abs(depth_ratio - 1.0) / 2.0)
                    else:
                        depth_score = max(0, depth_ratio - 0.3)  # Mild shrinkage ok (measurement error)
                else:
                    depth_score = 0.5

                total_score = (
                    dist_weight * dist_score
                    + clock_weight * clock_score
                    + depth_weight * depth_score
                )

                if total_score > best_score:
                    best_score = total_score
                    best_idx1 = idx1

            if best_idx1 is not None and best_score > 0.3:
                row1 = ml1.loc[best_idx1]
                confidence = "high" if best_score > 0.7 else ("medium" if best_score > 0.5 else "low")
                matched_pairs.append({
                    "y1_idx": best_idx1,
                    "y2_idx": idx2,
                    "y1_dist": float(row1["log_dist_ft"]),
                    "y2_dist": float(row2["log_dist_ft"]),
                    "y2_corrected_dist": float(corr_dist),
                    "y1_joint": row1.get("joint_number"),
                    "y2_joint": row2.get("joint_number"),
                    "y1_depth_pct": row1.get("depth_pct"),
                    "y2_depth_pct": row2.get("depth_pct"),
                    "y1_length_in": row1.get("length_in"),
                    "y2_length_in": row2.get("length_in"),
                    "y1_width_in": row1.get("width_in"),
                    "y2_width_in": row2.get("width_in"),
                    "y1_clock": row1.get("oclock_decimal"),
                    "y2_clock": row2.get("oclock_decimal"),
                    "y1_event": row1.get("event"),
                    "y2_event": row2.get("event"),
                    "y1_id_od": row1.get("id_od"),
                    "y2_id_od": row2.get("id_od"),
                    "score": round(best_score, 3),
                    "confidence": confidence,
                })
                used_y1.add(best_idx1)
                used_y2.add(idx2)

        # Identify new and missing anomalies
        new_in_y2 = ml2[~ml2.index.isin(used_y2)]
        missing_from_y1 = ml1[~ml1.index.isin(used_y1)]

        matches_df = pd.DataFrame(matched_pairs)
        self.matches[(y1, y2)] = matches_df

        return {
            "matched": len(matched_pairs),
            "new_in_later_run": len(new_in_y2),
            "missing_from_earlier_run": len(missing_from_y1),
            "high_confidence": len([m for m in matched_pairs if m["confidence"] == "high"]),
            "medium_confidence": len([m for m in matched_pairs if m["confidence"] == "medium"]),
            "low_confidence": len([m for m in matched_pairs if m["confidence"] == "low"]),
            "total_y1_metal_loss": len(ml1),
            "total_y2_metal_loss": len(ml2),
        }

    # ------------------------------------------------------------------
    # Phase 3: Growth rate calculation
    # ------------------------------------------------------------------

    def calculate_growth(self) -> dict:
        """Compute growth rates for all matched anomaly pairs."""
        year_gaps = {
            (2007, 2015): 8,
            (2015, 2022): 7,
            (2007, 2022): 15,
        }

        results = {}

        for (y1, y2), matches_df in self.matches.items():
            if matches_df.empty:
                continue

            gap = year_gaps.get((y1, y2), y2 - y1)
            growth_rows = []

            for _, row in matches_df.iterrows():
                d1 = row.get("y1_depth_pct")
                d2 = row.get("y2_depth_pct")
                l1 = row.get("y1_length_in")
                l2 = row.get("y2_length_in")
                w1 = row.get("y1_width_in")
                w2 = row.get("y2_width_in")

                depth_growth = (d2 - d1) / gap if (pd.notna(d1) and pd.notna(d2)) else None
                length_growth = (l2 - l1) / gap if (pd.notna(l1) and pd.notna(l2)) else None
                width_growth = (w2 - w1) / gap if (pd.notna(w1) and pd.notna(w2)) else None

                severity = "normal"
                if depth_growth is not None:
                    if depth_growth > 3.0:
                        severity = "critical"
                    elif depth_growth > 2.0:
                        severity = "high"
                    elif depth_growth > 1.0:
                        severity = "moderate"

                growth_rows.append({
                    **row.to_dict(),
                    "years_between": gap,
                    "depth_growth_pct_yr": round(depth_growth, 3) if depth_growth is not None else None,
                    "length_growth_in_yr": round(length_growth, 4) if length_growth is not None else None,
                    "width_growth_in_yr": round(width_growth, 4) if width_growth is not None else None,
                    "severity": severity,
                })

            growth_df = pd.DataFrame(growth_rows)
            self.growth[(y1, y2)] = growth_df

            # Stats
            valid_depth = growth_df["depth_growth_pct_yr"].dropna()
            results[f"{y1}->{y2}"] = {
                "total_matched": len(growth_df),
                "avg_depth_growth_pct_yr": round(float(valid_depth.mean()), 3) if len(valid_depth) > 0 else None,
                "max_depth_growth_pct_yr": round(float(valid_depth.max()), 3) if len(valid_depth) > 0 else None,
                "critical_count": int((growth_df["severity"] == "critical").sum()),
                "high_count": int((growth_df["severity"] == "high").sum()),
                "moderate_count": int((growth_df["severity"] == "moderate").sum()),
                "normal_count": int((growth_df["severity"] == "normal").sum()),
            }

        return results

    # ------------------------------------------------------------------
    # Query helpers
    # ------------------------------------------------------------------

    def get_top_growth(self, pair: tuple[int, int] | None = None, top_n: int = 20) -> list[dict]:
        """Return the fastest-growing anomalies."""
        if pair and pair in self.growth:
            df = self.growth[pair]
        else:
            # Combine all pairs
            dfs = list(self.growth.values())
            if not dfs:
                return []
            df = pd.concat(dfs, ignore_index=True)

        df = df.dropna(subset=["depth_growth_pct_yr"])
        df = df.sort_values("depth_growth_pct_yr", ascending=False).head(top_n)
        return df.to_dict(orient="records")

    def get_summary_stats(self) -> dict:
        """Return overall pipeline summary statistics."""
        stats: dict[str, Any] = {
            "file": self._file_path,
            "runs_loaded": sorted(self.runs.keys()),
        }

        for year, df in self.runs.items():
            anoms = self.anomalies.get(year, pd.DataFrame())
            ml = anoms[anoms["event"].apply(_is_metal_loss)] if len(anoms) > 0 else pd.DataFrame()
            depth_vals = ml["depth_pct"].dropna() if "depth_pct" in ml.columns else pd.Series(dtype=float)

            stats[f"run_{year}"] = {
                "total_features": len(df),
                "anomalies": len(anoms),
                "metal_loss": len(ml),
                "max_depth_pct": round(float(depth_vals.max()), 1) if len(depth_vals) > 0 else None,
                "avg_depth_pct": round(float(depth_vals.mean()), 1) if len(depth_vals) > 0 else None,
                "distance_range_ft": [
                    round(float(df["log_dist_ft"].min()), 1),
                    round(float(df["log_dist_ft"].max()), 1),
                ] if "log_dist_ft" in df.columns else None,
            }

        return stats

    def query_anomalies(self, filters: dict) -> list[dict]:
        """Query anomalies with filters: year, joint_min, joint_max, min_depth, severity, limit."""
        year = filters.get("year")
        pair_key = filters.get("pair")  # e.g. "2015->2022"

        if pair_key and self.growth:
            # Query growth data
            parts = pair_key.split("->")
            key = (int(parts[0]), int(parts[1]))
            df = self.growth.get(key, pd.DataFrame())
        elif year and year in self.anomalies:
            df = self.anomalies[year].copy()
        else:
            # Default: combine all anomalies
            dfs = [a.copy() for a in self.anomalies.values()]
            df = pd.concat(dfs, ignore_index=True) if dfs else pd.DataFrame()

        if df.empty:
            return []

        if "joint_min" in filters and "joint_number" in df.columns:
            df = df[df["joint_number"] >= filters["joint_min"]]
        if "joint_max" in filters and "joint_number" in df.columns:
            df = df[df["joint_number"] <= filters["joint_max"]]
        if "min_depth" in filters and "depth_pct" in df.columns:
            df = df[df["depth_pct"] >= filters["min_depth"]]
        if "severity" in filters and "severity" in df.columns:
            df = df[df["severity"] == filters["severity"]]

        limit = filters.get("limit", 50)
        df = df.head(limit)

        return df.to_dict(orient="records")

    def get_alignment_data(self) -> dict:
        """Return alignment data for visualization."""
        result: dict[str, Any] = {"weld_matches": [], "corrections": []}

        if self.aligned_welds is not None and not self.aligned_welds.empty:
            result["weld_matches"] = self.aligned_welds.to_dict(orient="records")

        for (y1, y2), func in self.correction_funcs.items():
            # Sample the correction function at regular intervals
            max_dist = max(
                float(self.runs[y2]["log_dist_ft"].max()),
                float(self.runs[y1]["log_dist_ft"].max()),
            )
            sample_dists = np.linspace(0, max_dist, 100)
            corrected = func(sample_dists)
            offsets = corrected - sample_dists

            result["corrections"].append({
                "pair": f"{y1}->{y2}",
                "sample_points": [
                    {"distance": round(float(d), 1), "offset": round(float(o), 3)}
                    for d, o in zip(sample_dists, offsets)
                ],
            })

        return result

    def get_match_details(self, pair: str, limit: int = 100, offset: int = 0) -> list[dict]:
        """Return detailed match data for a run pair."""
        parts = pair.split("->")
        key = (int(parts[0]), int(parts[1]))

        if key in self.growth:
            df = self.growth[key]
        elif key in self.matches:
            df = self.matches[key]
        else:
            return []

        df = df.iloc[offset:offset + limit]
        records = df.to_dict(orient="records")
        # Clean NaN values for JSON serialization
        for r in records:
            for k, v in r.items():
                if isinstance(v, float) and (math.isnan(v) or math.isinf(v)):
                    r[k] = None
        return records

    def get_profile_data(self, year: int) -> list[dict]:
        """Return distance vs depth data for pipeline profile chart."""
        if year not in self.anomalies:
            return []

        anoms = self.anomalies[year]
        ml = anoms[anoms["event"].apply(_is_metal_loss)].copy()

        if ml.empty:
            return []

        result = []
        for _, row in ml.iterrows():
            entry: dict[str, Any] = {
                "log_dist_ft": round(float(row["log_dist_ft"]), 2) if pd.notna(row.get("log_dist_ft")) else None,
                "depth_pct": round(float(row["depth_pct"]), 1) if pd.notna(row.get("depth_pct")) else None,
                "event": row.get("event"),
            }
            if "oclock_decimal" in row and pd.notna(row.get("oclock_decimal")):
                entry["oclock"] = round(float(row["oclock_decimal"]), 2)
            if "joint_number" in row and pd.notna(row.get("joint_number")):
                entry["joint"] = int(row["joint_number"])
            result.append(entry)

        return result


# ---------------------------------------------------------------------------
# Module-level singleton for reuse across tool calls
# ---------------------------------------------------------------------------

_dataset: ILIDataset | None = None


def get_dataset() -> ILIDataset:
    global _dataset
    if _dataset is None:
        _dataset = ILIDataset()
    return _dataset


def reset_dataset():
    global _dataset
    _dataset = None
