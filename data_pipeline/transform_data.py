"""
Transform phase: join NHS appointments, GP patient list, and QOF datasets.
Calculates DNA Rate, Wasted Capacity, runs K-Means clustering to assign
practice Archetypes, and computes the Benchmark Gap metric.
Outputs: data_pipeline/output/practice_data.json
"""

import json
import logging
import sys
import zipfile
from datetime import datetime, timezone
from pathlib import Path

import numpy as np
import pandas as pd
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
RAW_DATA_DIR = Path(__file__).parent / "raw_data"
OUTPUT_DIR = Path(__file__).parent / "output"
OUTPUT_FILE = OUTPUT_DIR / "practice_data.json"

# £40 per missed 10-minute GP appointment (NHS England published estimate)
NHS_APPT_COST_GBP = 40.0
# QOF point value 2024-25 (NHS England: total QOF pool / total achievable points)
QOF_POINT_VALUE_GBP = 200.0
# Number of Archetype clusters for K-Means
N_CLUSTERS = 5
RANDOM_STATE = 42

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)],
)
log = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Extract helpers
# ---------------------------------------------------------------------------
def load_practice_appointments() -> pd.DataFrame:
    """
    Load the most recent Practice_Level_Crosstab CSV from its ZIP.
    Aggregates COUNT_OF_APPOINTMENTS by GP_CODE and APPT_STATUS.
    Returns columns: gp_code, total_appointments, dna_count
    """
    zips = sorted(RAW_DATA_DIR.glob("Practice_Level_Crosstab_*.zip"), reverse=True)
    if not zips:
        raise FileNotFoundError(
            "No Practice_Level_Crosstab ZIP found in raw_data/. "
            "Run scrape_appointments.py first."
        )
    latest_zip = zips[0]
    log.info("Loading appointments from %s", latest_zip.name)

    # Parse month-year from filenames to select the most recent month correctly
    _MONTH_MAP = {
        "jan": 1, "feb": 2, "mar": 3, "apr": 4, "may": 5, "jun": 6,
        "jul": 7, "aug": 8, "sep": 9, "oct": 10, "nov": 11, "dec": 12,
    }

    def _csv_sort_key(name: str):
        """Return (year, month) tuple so files sort by real calendar date."""
        import re
        m = re.search(r"_([A-Za-z]{3})_(\d{2})\.csv$", name)
        if m:
            month = _MONTH_MAP.get(m.group(1).lower(), 0)
            year = 2000 + int(m.group(2))
            return (year, month)
        return (0, 0)

    with zipfile.ZipFile(latest_zip) as z:
        csv_files = sorted(
            [n for n in z.namelist() if n.startswith("Practice_Level_Crosstab_") and n.endswith(".csv")],
            key=_csv_sort_key,
            reverse=True,
        )
        if not csv_files:
            raise FileNotFoundError(f"No practice-level CSV found inside {latest_zip.name}")
        target = csv_files[0]
        log.info("Reading %s", target)
        with z.open(target) as f:
            df = pd.read_csv(f, dtype=str)

    df["COUNT_OF_APPOINTMENTS"] = pd.to_numeric(df["COUNT_OF_APPOINTMENTS"], errors="coerce").fillna(0)

    # Exclude "Unknown" status — only count confirmed Attended and DNA
    df = df[df["APPT_STATUS"].isin(["Attended", "DNA"])]

    agg = (
        df.groupby(["GP_CODE", "GP_NAME", "SUB_ICB_LOCATION_CODE", "SUB_ICB_LOCATION_NAME", "APPT_STATUS"])["COUNT_OF_APPOINTMENTS"]
        .sum()
        .unstack(fill_value=0)
        .reset_index()
    )

    agg.columns.name = None
    for col in ["Attended", "DNA"]:
        if col not in agg.columns:
            agg[col] = 0

    agg["total_appointments"] = agg["Attended"] + agg["DNA"]
    agg["dna_count"] = agg["DNA"]
    agg = agg.rename(columns={
        "GP_CODE": "gp_code",
        "GP_NAME": "gp_name",
        "SUB_ICB_LOCATION_CODE": "sub_icb_code",
        "SUB_ICB_LOCATION_NAME": "sub_icb_name",
    })

    # Drop practices with no confirmed appointments
    agg = agg[agg["total_appointments"] > 0].copy()
    log.info("Loaded appointment data for %d practices", len(agg))
    return agg[["gp_code", "gp_name", "sub_icb_code", "sub_icb_name", "total_appointments", "dna_count"]]


def load_gp_list_sizes() -> pd.DataFrame:
    """
    Load GP patient list sizes from gp-reg-pat-prac-all.zip.
    Returns columns: gp_code, list_size
    """
    zips = sorted(RAW_DATA_DIR.glob("gp-reg-pat-prac-all*.zip"), reverse=True)
    if not zips:
        raise FileNotFoundError(
            "No gp-reg-pat-prac-all ZIP found in raw_data/. "
            "Run scrape_gp_patients.py first."
        )
    log.info("Loading GP list sizes from %s", zips[0].name)

    with zipfile.ZipFile(zips[0]) as z:
        with z.open("gp-reg-pat-prac-all.csv") as f:
            df = pd.read_csv(f, dtype=str)

    # Filter to total list size row: SEX=ALL, AGE=ALL, TYPE=GP
    totals = df[(df["SEX"] == "ALL") & (df["AGE"] == "ALL") & (df["TYPE"] == "GP")].copy()
    totals["list_size"] = pd.to_numeric(totals["NUMBER_OF_PATIENTS"], errors="coerce")
    totals = totals.rename(columns={"CODE": "gp_code"})
    totals = totals[["gp_code", "list_size"]].dropna()
    log.info("Loaded list sizes for %d practices", len(totals))
    return totals


def load_qof_data() -> pd.DataFrame:
    """
    Load QOF achievement data from QOF raw CSV ZIP.
    Returns columns: gp_code, qof_achieved_points, qof_max_points
    """
    zips = sorted(RAW_DATA_DIR.glob("QOF*.zip"), reverse=True)
    if not zips:
        raise FileNotFoundError(
            "No QOF ZIP found in raw_data/. "
            "Run scrape_qof.py first."
        )
    log.info("Loading QOF data from %s", zips[0].name)

    regional_achievement_files = []
    indicator_mapping = None

    with zipfile.ZipFile(zips[0]) as z:
        all_files = z.namelist()

        # Load indicator mapping for max points per indicator
        mapping_file = next((n for n in all_files if "MAPPING_INDICATORS" in n), None)
        if mapping_file:
            with z.open(mapping_file) as f:
                indicator_mapping = pd.read_csv(f, dtype=str)
            indicator_mapping["max_points"] = pd.to_numeric(
                indicator_mapping["INDICATOR_POINT_VALUE"], errors="coerce"
            ).fillna(0)

        # Load all regional achievement CSVs
        achievement_files = [n for n in all_files if n.startswith("ACHIEVEMENT_") and n.endswith(".csv")]
        dfs = []
        for fname in achievement_files:
            with z.open(fname) as f:
                df = pd.read_csv(f, dtype=str)
                dfs.append(df)

    if not dfs:
        raise FileNotFoundError("No ACHIEVEMENT CSV files found in QOF ZIP.")

    achievement = pd.concat(dfs, ignore_index=True)
    achievement["VALUE"] = pd.to_numeric(achievement["VALUE"], errors="coerce").fillna(0)

    # Extract achieved points per practice
    achieved = (
        achievement[achievement["MEASURE"] == "ACHIEVED_POINTS"]
        .groupby("PRACTICE_CODE")["VALUE"]
        .sum()
        .reset_index()
        .rename(columns={"PRACTICE_CODE": "gp_code", "VALUE": "qof_achieved_points"})
    )

    # Compute max possible points (sum of all indicator point values)
    if indicator_mapping is not None:
        total_max = indicator_mapping["max_points"].sum()
        log.info("QOF total max achievable points: %.0f", total_max)
    else:
        total_max = 635.0  # Published QOF max for 2024-25
        log.warning("Indicator mapping not found; using default max of %.0f points", total_max)

    achieved["qof_max_points"] = total_max
    log.info("Loaded QOF data for %d practices", len(achieved))
    return achieved


# ---------------------------------------------------------------------------
# Transform
# ---------------------------------------------------------------------------
def calculate_metrics(df: pd.DataFrame) -> pd.DataFrame:
    """Calculate DNA rate, wasted capacity, and QOF at-risk metrics."""
    df["dna_rate_pct"] = (df["dna_count"] / df["total_appointments"] * 100).round(2)
    df["wasted_capacity_gbp"] = (df["dna_count"] * NHS_APPT_COST_GBP).round(2)

    df["qof_achieved_points"] = df["qof_achieved_points"].fillna(0).round(1)
    df["qof_max_points"] = df["qof_max_points"].fillna(635.0).round(1)
    df["qof_pct"] = (
        (df["qof_achieved_points"] / df["qof_max_points"] * 100)
        .where(df["qof_max_points"] > 0, 0)
        .round(1)
    )
    df["qof_at_risk_gbp"] = (
        (df["qof_max_points"] - df["qof_achieved_points"]) * QOF_POINT_VALUE_GBP
    ).clip(lower=0).round(2)

    return df


def assign_archetypes(df: pd.DataFrame) -> pd.DataFrame:
    """
    Run K-Means clustering on (list_size, dna_rate_pct) to assign
    each practice an Archetype cluster (0–4).
    """
    features = df[["list_size", "dna_rate_pct"]].copy()
    # Drop rows with missing clustering features
    valid_mask = features.notna().all(axis=1)
    log.info(
        "Clustering %d practices (%d excluded due to missing list size/DNA rate)",
        valid_mask.sum(),
        (~valid_mask).sum(),
    )

    scaler = StandardScaler()
    X = scaler.fit_transform(features[valid_mask])

    kmeans = KMeans(n_clusters=N_CLUSTERS, random_state=RANDOM_STATE, n_init=10)
    df.loc[valid_mask, "archetype"] = kmeans.fit_predict(X).astype(int)
    df["archetype"] = df["archetype"].fillna(-1).astype(int)

    # Label archetypes by ascending average list size for interpretability
    archetype_order = (
        df[df["archetype"] >= 0]
        .groupby("archetype")["list_size"]
        .mean()
        .sort_values()
        .index.tolist()
    )
    label_map = {old: new for new, old in enumerate(archetype_order)}
    df["archetype"] = df["archetype"].map(lambda x: label_map.get(x, -1))

    log.info("Archetype distribution:\n%s", df["archetype"].value_counts().sort_index().to_string())
    return df


def calculate_benchmark_gap(df: pd.DataFrame) -> pd.DataFrame:
    """
    For each practice, calculate the gap between its DNA rate and the
    top 10% (lowest DNA rate) performers within the same Archetype cluster.
    """
    def top_10_pct_threshold(group: pd.Series) -> float:
        return group.quantile(0.10)

    cluster_thresholds = (
        df[df["archetype"] >= 0]
        .groupby("archetype")["dna_rate_pct"]
        .agg(top_10_pct_threshold)
        .rename("cluster_top10_dna_rate")
    )

    df = df.join(cluster_thresholds, on="archetype")
    df["benchmark_gap_pct"] = (df["dna_rate_pct"] - df["cluster_top10_dna_rate"]).round(2)
    df.drop(columns=["cluster_top10_dna_rate"], inplace=True)
    return df


def build_archetype_summary(df: pd.DataFrame) -> dict:
    """Build a summary dict for each archetype cluster."""
    archetype_labels = {
        0: "Small Practice",
        1: "Small-Medium Practice",
        2: "Medium Practice",
        3: "Medium-Large Practice",
        4: "Large Practice",
    }
    summary = {}
    for archetype_id, group in df[df["archetype"] >= 0].groupby("archetype"):
        summary[str(archetype_id)] = {
            "label": archetype_labels.get(archetype_id, f"Archetype {archetype_id}"),
            "count": int(len(group)),
            "avg_list_size": round(float(group["list_size"].mean()), 0),
            "avg_dna_rate_pct": round(float(group["dna_rate_pct"].mean()), 2),
            "top10_dna_rate_pct": round(float(group["dna_rate_pct"].quantile(0.10)), 2),
        }
    return summary


# ---------------------------------------------------------------------------
# Load (output)
# ---------------------------------------------------------------------------
def write_output(df: pd.DataFrame, archetype_summary: dict) -> None:
    """Serialise the final dataset to practice_data.json."""
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    practice_records = []
    for _, row in df.iterrows():
        practice_records.append({
            "gp_code": row["gp_code"],
            "gp_name": row["gp_name"],
            "sub_icb_code": row.get("sub_icb_code", ""),
            "sub_icb_name": row.get("sub_icb_name", ""),
            "list_size": int(row["list_size"]) if pd.notna(row.get("list_size")) else None,
            "total_appointments": int(row["total_appointments"]),
            "dna_count": int(row["dna_count"]),
            "dna_rate_pct": float(row["dna_rate_pct"]),
            "wasted_capacity_gbp": float(row["wasted_capacity_gbp"]),
            "archetype": int(row["archetype"]),
            "benchmark_gap_pct": float(row["benchmark_gap_pct"]) if pd.notna(row.get("benchmark_gap_pct")) else None,
            "qof_achieved_points": float(row["qof_achieved_points"]) if pd.notna(row.get("qof_achieved_points")) else None,
            "qof_max_points": float(row["qof_max_points"]) if pd.notna(row.get("qof_max_points")) else None,
            "qof_pct": float(row["qof_pct"]) if pd.notna(row.get("qof_pct")) else None,
            "qof_at_risk_gbp": float(row["qof_at_risk_gbp"]) if pd.notna(row.get("qof_at_risk_gbp")) else None,
        })

    output = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "practice_count": len(practice_records),
        "archetypes": archetype_summary,
        "practices": practice_records,
    }

    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(output, f, ensure_ascii=False, separators=(",", ":"))

    size_kb = OUTPUT_FILE.stat().st_size // 1024
    log.info("Output written: %s (%d KB, %d practices)", OUTPUT_FILE, size_kb, len(practice_records))


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main() -> None:
    try:
        log.info("=== PRAQTIS Transform Phase Starting ===")

        # Extract
        appointments = load_practice_appointments()
        list_sizes = load_gp_list_sizes()
        qof = load_qof_data()

        # Join — appointments is the spine; left-join list sizes and QOF
        df = appointments.merge(list_sizes, on="gp_code", how="left")
        df = df.merge(qof, on="gp_code", how="left")
        log.info(
            "Joined dataset: %d practices (%d with list size, %d with QOF data)",
            len(df),
            df["list_size"].notna().sum(),
            df["qof_achieved_points"].notna().sum(),
        )

        # Transform
        df = calculate_metrics(df)
        df = assign_archetypes(df)
        df = calculate_benchmark_gap(df)
        archetype_summary = build_archetype_summary(df)

        # Load
        write_output(df, archetype_summary)

        log.info("=== Transform Phase Complete ===")

    except FileNotFoundError as exc:
        log.error("Missing data file: %s", exc)
        sys.exit(1)
    except Exception as exc:
        log.error("Unexpected error: %s", exc, exc_info=True)
        sys.exit(1)


if __name__ == "__main__":
    main()
