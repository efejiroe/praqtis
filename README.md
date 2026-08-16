# PCN-ARRS

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
fetch/aggregate pipeline), and Phase 2 (national funnel-plot outlier
flagging on staffing) are complete. Currently scoped as an MVP: pull
data, aggregate to PCN, run the national funnel-plot check — nothing
else. Phase 3 (parameterised Quarto report) has a first draft in
progress.

## Features

- **GP-practice-level data, aggregated to PCN** — every source is
  collated at practice level first and pooled to PCN ourselves, even
  where NHS Digital also publishes ready-made PCN-level rows.
- **National funnel-plot outlier flagging on staffing** —
  Spiegelhalter's overdispersion-adjusted method (via `FunnelPlotR`), run
  nationally so a PCN is identified because its staffing is a
  statistical outlier against expected need, not just because it tops a
  ranking; control limits reflect the true national spread, so small
  PCNs aren't flagged just for being small and noisy.
- **Age- and deprivation-adjusted expected staffing** — "expected FTE" is
  self-fitted (a quasipoisson rate regression on each PCN's own
  population composition — age, sex, and IMD-quintile shares — with list
  size as the exposure offset; see `src/compute_funnel.R`), not imported
  from an external formula. As a corroboration check (not a production
  input), the fitted rate ratios are compared against published figures
  from Mukhtar TK, Bankhead C, Stevens S, Perera R, Holt TA, Salisbury C,
  Hobbs FDR. "Factors associated with consultation rates in general
  practice in England, 2013–2014: a cross-sectional study." *Br J Gen
  Pract* 2018;68(670):e370-e377. DOI:
  [10.3399/bjgp18X695981](https://doi.org/10.3399/bjgp18X695981) (open
  access, CC BY-NC 4.0). Deprivation terms corroborate closely;
  age terms diverge substantially — see
  `targets::tar_read(national_staffing_model_comparison)` and
  `src/compute_funnel.R` for the numbers and discussion.

## Usage

```r
renv::restore()      # install pinned dependencies
targets::tar_make()  # run the pipeline
targets::tar_read(national_staffing_funnel_flags)   # e.g. inspect the funnel-plot output
```

Public-data snapshots and their sources are recorded in
`dat/in/MANIFEST.md`. Rebuilt outputs (`dat/out/`, `_targets/`) are
gitignored, not committed.
