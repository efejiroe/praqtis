# PRAQTIS — NHS GP Practice Intelligence Tool

An automated, serverless ETL pipeline and scrollytelling web app that benchmarks every NHS GP practice in England against its data-science-defined peers. Built for [REPLIQR](https://repliqr.com) as a lead-generation decision intelligence tool.

---

## What it does

Each month, a GitHub Actions workflow automatically:

1. **Extracts** three public NHS Digital datasets
2. **Transforms** them — joining on ODS practice code, calculating metrics, and running K-Means clustering
3. **Loads** a single flat `practice_data.json` file back into this repository

The front-end (`web_app/`) reads this file to serve a five-screen scrollytelling narrative: find your practice → see your cost → benchmark against peers → understand the root cause → get the EASY fix.

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
├── .github/workflows/
│   └── nhs_etl_pipeline.yml        # Automated monthly pipeline (GitHub Actions)
├── .claudeignore                    # Large files excluded from AI context windows
├── data_pipeline/
│   ├── scrape_appointments.py       # Extract: Appointments in General Practice
│   ├── scrape_gp_patients.py        # Extract: GP patient list sizes
│   ├── scrape_qof.py                # Extract: QOF achievement data
│   ├── transform_data.py            # Transform & Load: join, cluster, output JSON
│   ├── requirements.txt
│   ├── raw_data/                    # Downloaded NHS source files (gitignored)
│   └── output/
│       └── practice_data.json       # Final output — consumed by the front-end
├── docs/
│   ├── 01_PRD.md                    # Product Requirements Document
│   ├── 02_Architecture.md           # Pipeline & tech stack architecture
│   ├── 03_Logic_and_Metrics.md      # Calculations and behavioral science model
│   ├── 04_UX_Narrative.md           # Screen-by-screen UX flow
│   └── archive/                     # Completed task delegation files
└── web_app/                         # Next.js scrollytelling front-end
    ├── app/page.tsx                 # Main orchestrator page
    ├── components/
    │   ├── HookView.tsx             # View 1: Practice search
    │   ├── RevealView.tsx           # View 2: Count-up wasted capacity
    │   ├── ContextView.tsx          # View 3: Benchmark vs archetype peers
    │   ├── FrequentFlyersView.tsx   # View 4: Root cause — Pareto / frequent flyers
    │   └── FixView.tsx              # View 5: EASY framework nudges + ROI
    ├── lib/types.ts                 # TypeScript interfaces
    └── public/data/
        └── practice_data.json       # Static data served to the client
```

---

## Running the Pipeline Locally

```bash
pip install -r data_pipeline/requirements.txt

python data_pipeline/scrape_appointments.py
python data_pipeline/scrape_gp_patients.py
python data_pipeline/scrape_qof.py
python data_pipeline/transform_data.py
```

Output is written to `data_pipeline/output/practice_data.json`.

---

## Running the Web App Locally

```bash
cd web_app
npm install
npm run dev
```

Open `http://localhost:3000`. The app fetches `practice_data.json` from `public/data/` at runtime.

For a production build: `npm run build`.

---

## Deploying

Connect `efejiroe/praqtis` to [Vercel](https://vercel.com). Set root directory to `web_app`. Zero-config Next.js deploy.

After each ETL run, the GitHub Action commits the refreshed `practice_data.json` to `data_pipeline/output/`. Copy or symlink this to `web_app/public/data/` (or use a Vercel build hook) to keep the front-end in sync.

---

## Pipeline Schedule

The GitHub Action runs at **midnight UTC on the 15th of every month**, the day after NHS Digital typically publishes the previous month's appointment data. It can also be triggered manually from the [Actions tab](../../actions/workflows/nhs_etl_pipeline.yml).

---

## Status

| Phase | Status |
|---|---|
| Extract (Appointments) | Complete |
| Extract (GP Patients) | Complete |
| Extract (QOF) | Complete |
| Transform & Cluster | Complete |
| Load (JSON output) | Complete |
| Front-end (Next.js scrollytelling) | Complete — awaiting Vercel deploy |
