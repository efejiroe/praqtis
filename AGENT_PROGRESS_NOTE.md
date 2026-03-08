# Agent Progress Note: Tasks 1 & 2 — NHS Data Pipeline (Extract + Transform)
**From:** Claude Sonnet 4.6 (same agent, single session)
**To:** Supervisor (Antigravity)
**Date:** 2026-03-08
**Status:** COMPLETE — Pipeline end-to-end. Awaiting front-end task.

---

## Token Budget (Transparency)
This session was long. My estimate is that I have consumed approximately **65–75% of my context window**. I am still operational but Antigravity should be aware that if another large task is delegated in this same conversation, a fresh session is recommended to avoid degraded performance near the limit. The next task (front-end) should be started in a new Claude Code session.

---

## Task 1 Summary (Extract Phase) — COMPLETE

### What was built
- `data_pipeline/scrape_appointments.py` — scrapes and downloads the latest "Appointments in General Practice" practice-level ZIP from NHS Digital.
- `data_pipeline/requirements.txt` — minimal deps (`requests`, `beautifulsoup4`).
- `.github/workflows/nhs_etl_pipeline.yml` — initial GitHub Actions scaffold.
- Initial commit `5e3fad2` pushed to `efejiroe/praqtis` on GitHub.

### Test result
`Appointments_GP_Daily_CSV_Jan_26.zip` downloaded successfully (53 MB). Exit code 0.

### Issues resolved this session
- GitHub PAT lacked `repo` scope on the original token. User supplied a new fine-grained PAT.
- Repo had two branches (`main`, `master`) with unrelated histories. Resolved by force-pushing `master` onto `main`, deleting `master`, and re-establishing the clean `praqtis/` working directory from the remote.
- **Active working directory is now:** `04 Product and Technology/praqtis/` (lowercase). The old `PRAQTIS/` folder can be deleted.

---

## Task 2 Summary (Transform & Load Phase) — COMPLETE

### Step A: Additional Extract Scripts
Two new scrapers added, following the same pattern as `scrape_appointments.py`:

| File | Dataset | Source | Frequency |
|---|---|---|---|
| `scrape_gp_patients.py` | Patients Registered at a GP Practice | NHS Digital | Monthly |
| `scrape_qof.py` | Quality & Outcomes Framework (QOF) | NHS Digital | Annual |

Both scripts auto-detect the latest publication year/month from the index page, making them forward-compatible as new data is published.

### Step B: Transform Script (`transform_data.py`)

Full data science pipeline. Key design decisions:

**Data joins:**
- Spine: `Practice_Level_Crosstab_Jan_26.csv` (practice-level appointments, inside the ZIP). Note: the sub-ICB level file (`Appointments_GP_Daily_CSV_Jan_26.zip`) was originally downloaded — the correct practice-level annex file (`Practice_Level_Crosstab_Jan_26.zip`) was identified and added.
- Left-joined: GP patient list sizes (on `gp_code` = ODS code).
- Left-joined: QOF achievement data (7 regional CSVs concatenated, then aggregated by practice).

**Metrics calculated:**

| Metric | Formula |
|---|---|
| DNA Rate % | `DNA / (DNA + Attended) × 100` |
| Wasted Capacity £ | `DNA count × £40` |
| QOF % | `Achieved points / 635 × 100` |
| QOF At-Risk £ | `(635 − achieved points) × £200` |
| Benchmark Gap % | `Practice DNA rate − Top 10% cluster threshold` |

**K-Means clustering:**
- Features: `list_size`, `dna_rate_pct` (both StandardScaler normalised).
- `k=5` archetypes, `random_state=42`, `n_init=10`.
- Archetypes relabelled 0–4 in ascending list size order for front-end interpretability.

**Bug fixed during testing:** CSV files inside the ZIP were sorting alphabetically by month name (Nov > Jan), causing the wrong month to be loaded. Fixed with a date-aware sort key that extracts `(year, month)` from filenames.

### Step C: Load & GitHub Actions

- Output: `data_pipeline/output/practice_data.json` — committed to the repo.
- GitHub Actions workflow updated to run the full ETL sequence and commit the output JSON on completion.
- `.gitignore` added to exclude raw data ZIPs (too large; downloaded fresh each run).
- `README.md` written and published.

### Test Results

| Check | Result |
|---|---|
| Appointments loaded | ✅ 6,140 practices (Jan 2026) |
| List sizes joined | ✅ 6,140 / 6,140 matched |
| QOF data joined | ✅ 6,135 / 6,140 matched |
| Clustering | ✅ 5 archetypes (sizes: 122 → 2,762) |
| Output JSON | ✅ 2.2 MB, 6,140 records |
| Committed to `main` | ✅ Commit `3e7e2f4` |

---

## Repository State
- **Remote:** `https://github.com/efejiroe/praqtis` — single `main` branch.
- **Local:** `04 Product and Technology/praqtis/` — clean, tracking `origin/main`.
- **Commits:** `5e3fad2` (scaffold) → `3e7e2f4` (full ETL).

---

## Recommended Next Task for Supervisor (Task 3)
**Front-end: React/Next.js "scrollytelling" application.**

Per `04_UX_Narrative.md` and `02_Architecture.md`:
- Framework: Next.js + Tailwind CSS.
- Data source: reads `practice_data.json` statically (no API calls).
- Key screens: practice lookup → DNA rate reveal → Wasted Capacity £ → Archetype benchmarking → QOF at-risk → Causal Loop interactive widget.
- Animations: GSAP ScrollTrigger or Scrollama.js.
- Hosting: Vercel or Netlify.

Suggested task file: `CLAUDE_TASK_3.md`
