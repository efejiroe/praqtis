# PRAQTIS — NHS GP Practice Intelligence Pipeline

An automated, serverless ETL pipeline that benchmarks every NHS GP practice in England against its data-science-defined peers. Built for [REPLIQR](https://repliqr.com) as the data backbone of the PRAQTIS decision intelligence tool.

---

## What it does

Each month, a GitHub Actions workflow automatically:

1. **Extracts** three public NHS Digital datasets
2. **Transforms** them — joining on ODS practice code, calculating metrics, and running K-Means clustering
3. **Loads** a single flat `practice_data.json` file back into this repository, ready for the front-end to consume

No database. No server. No cost.

---

## The Metrics

| Metric | Formula | Purpose |
|---|---|---|
| **DNA Rate %** | DNAs / (DNAs + Attended) × 100 | Core measure of non-attendance |
| **Wasted Capacity £** | DNA count × £40 | Financial cost of missed appointments |
| **Archetype** | K-Means cluster (list size + DNA rate) | Groups practices with identical peers |
| **Benchmark Gap %** | Practice DNA rate − Top 10% cluster rate | Shows gap vs realistic best-in-class |
| **QOF At-Risk £** | Unachieved QOF points × £200/point | Estimated bonus revenue at risk |

---

## Data Sources

All data is publicly released by NHS England Digital under the [Open Government Licence](https://www.nationalarchives.gov.uk/doc/open-government-licence/).

| Dataset | Publisher | Frequency |
|---|---|---|
| [Appointments in General Practice](https://digital.nhs.uk/data-and-information/publications/statistical/appointments-in-general-practice) | NHS England | Monthly |
| [Patients Registered at a GP Practice](https://digital.nhs.uk/data-and-information/publications/statistical/patients-registered-at-a-gp-practice) | NHS England | Monthly |
| [Quality and Outcomes Framework (QOF)](https://digital.nhs.uk/data-and-information/publications/statistical/quality-and-outcomes-framework-achievement-prevalence-and-exceptions-data) | NHS England | Annual |

---

## Repository Structure

```
PRAQTIS/
├── .github/
│   └── workflows/
│       └── nhs_etl_pipeline.yml   # Automated monthly pipeline (GitHub Actions)
├── data_pipeline/
│   ├── scrape_appointments.py     # Extract: Appointments in General Practice
│   ├── scrape_gp_patients.py      # Extract: GP patient list sizes
│   ├── scrape_qof.py              # Extract: QOF achievement data
│   ├── transform_data.py          # Transform & Load: join, cluster, output JSON
│   ├── requirements.txt
│   ├── raw_data/                  # Downloaded NHS source files (not committed)
│   └── output/
│       └── practice_data.json     # Final output — consumed by the front-end
└── docs/
    ├── _HANDOVER.md
    ├── 01_PRD.md
    ├── 02_Architecture.md
    ├── 03_Logic_and_Metrics.md
    └── 04_UX_Narrative.md
```

---

## Running Locally

```bash
# Install dependencies
pip install -r data_pipeline/requirements.txt

# Extract
python data_pipeline/scrape_appointments.py
python data_pipeline/scrape_gp_patients.py
python data_pipeline/scrape_qof.py

# Transform & Load
python data_pipeline/transform_data.py
```

The output is written to `data_pipeline/output/practice_data.json`.

---

## Output Format

```json
{
  "generated_at": "2026-01-15T00:05:23+00:00",
  "practice_count": 6140,
  "archetypes": {
    "0": { "label": "Small Practice", "count": 1622, "avg_dna_rate_pct": 4.1 },
    "4": { "label": "Large Practice", "count": 122, "avg_dna_rate_pct": 3.8 }
  },
  "practices": [
    {
      "gp_code": "A81001",
      "gp_name": "THE DENSHAM SURGERY",
      "list_size": 3753,
      "dna_rate_pct": 5.2,
      "wasted_capacity_gbp": 2960.0,
      "archetype": 0,
      "benchmark_gap_pct": 2.8,
      "qof_at_risk_gbp": 14200.0
    }
  ]
}
```

---

## Architecture

```
GitHub Actions (cron: 15th of each month)
        │
        ▼
  Python scraper × 3 ──► NHS Digital (public CSVs)
        │
        ▼
  transform_data.py
    ├── pandas  — join & aggregate
    ├── scikit-learn — K-Means clustering (5 archetypes)
    └── json    — flat file output
        │
        ▼
  practice_data.json  ──► Front-end (Next.js / React)
```

---

## Pipeline Schedule

The GitHub Action runs automatically at **midnight UTC on the 15th of every month**, one day after NHS Digital typically publishes the previous month's appointment data.

It can also be triggered manually from the [Actions tab](../../actions/workflows/nhs_etl_pipeline.yml).

---

## Status

| Phase | Status |
|---|---|
| Extract (Appointments) | Complete |
| Extract (GP Patients) | Complete |
| Extract (QOF) | Complete |
| Transform & Cluster | Complete |
| Load (JSON output) | Complete |
| Front-end (React/Next.js) | Planned |
