# PRAQTIS

A reproducible NHS primary-care analytics pipeline that identifies where
a small operational change would yield the largest improvement for a
Primary Care Network (PCN), and renders the finding as a parameterised,
per-PCN report.

Built with [`{targets}`](https://books.ropensci.org/targets/) and
[`renv`](https://rstudio.github.io/renv/), on public NHS England Digital
and OHID Fingertips data only — no patient-level data anywhere in the
pipeline.

## Status

Phased build (see `CLAUDE.md` for the full roadmap and constraints).
Phase 0 (data-availability reconnaissance), Phase 1 (single-PCN
fetch/aggregate pipeline), and Phase 2 (scoring — ROS, TPG, PPD,
funnel-plot flagging) are complete. Phase 3 (parameterised Quarto
report) has a first draft in progress.

## Features

- **GP-practice-level data, aggregated to PCN** — every source is
  collated at practice level first and pooled to PCN ourselves, even
  where NHS Digital also publishes ready-made PCN-level rows. This keeps
  practice-level drill-down available throughout, not just PCN summaries.
- **Recruitment Opportunity Score (ROS)** — flags where patient need,
  weighted by deprivation, is outgrowing current staffing, to direct
  the next ARRS hire.
- **Threshold Proximity Gap (TPG)** — the gap between a PCN's current
  performance and the funding threshold it's currently missing.
- **Peer Performance Deficit (PPD)** — benchmarks a PCN against a
  nationally-built "like-PCN" peer group (nearest-neighbour clustering
  on list size, deprivation, and disease prevalence), not the national
  average, which flattens very different PCNs into one number.
- **Funnel-plot outlier flagging** — Spiegelhalter's overdispersion-
  adjusted method (via `FunnelPlotR`), run nationally so control limits
  reflect the true spread of PCN performance and small PCNs aren't
  flagged just for being small and noisy.
- **Practice-level drill-down** (`src/lookup_practice.R`) — once a PCN-
  level gap is worth investigating, `practice_snapshot()` and
  `practice_vs_pcn()` pull a single practice's own numbers and compare
  them against its PCN's average, to help identify which practice (and
  which lever) is actually driving the gap.

## Usage

```r
renv::restore()      # install pinned dependencies
targets::tar_make()  # run the pipeline
targets::tar_read(pilot_pcn_ros)   # e.g. inspect a target's output
```

Public-data snapshots and their sources are recorded in
`dat/in/MANIFEST.md`. Rebuilt outputs (`dat/out/`, `_targets/`) are
gitignored, not committed.
