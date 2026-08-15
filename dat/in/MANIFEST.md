# dat/in MANIFEST

Committed public-data snapshots. Each entry: source URL, download date, and
the vintage the file itself claims to be.

## gp-reg-pat-prac-map.zip

- **Source**: NHS England Digital, "Patients Registered at a GP Practice"
  monthly publication — practice-to-PCN-to-ICB mapping file
  https://digital.nhs.uk/data-and-information/publications/statistical/patients-registered-at-a-gp-practice/july-2026
- **Direct URL**: https://files.digital.nhs.uk/98/8142DB/gp-reg-pat-prac-map.zip
- **Downloaded**: 2026-08-06
- **Vintage**: July 2026 publication, extract date 01 Jul 2026

## gp-reg-pat-prac-quin-age.zip

- **Source**: NHS England Digital, "Patients Registered at a GP Practice"
  monthly publication — 5-year age band registered patient counts, by
  Commissioning Region / ICB / sub-ICB location / PCN / GP practice
  https://digital.nhs.uk/data-and-information/publications/statistical/patients-registered-at-a-gp-practice/july-2026
- **Direct URL**: https://files.digital.nhs.uk/BB/362F1A/gp-reg-pat-prac-quin-age.zip
- **Downloaded**: 2026-08-06
- **Vintage**: July 2026 publication, extract date 2026-07-01

## fingertips-imd-2025-gp-practice.csv

- **Source**: OHID Fingertips API, indicator 94240 "Deprivation score (IMD
  2025)", fetched via `fingertipsR::fingertips_data()` — not a static
  file, so the API response is cached here for reproducibility
  https://fingertips.phe.org.uk/profile/general-practice
- **Downloaded**: 2026-08-07
- **Vintage**: IMD 2025, GP-practice level (AreaTypeID 7)

## GPWPracticeCSV.062026.zip

- **Source**: NHS England Digital, "General Practice Workforce" monthly
  publication — practice-level FTE by staff group
  https://digital.nhs.uk/data-and-information/publications/statistical/general-and-personal-medical-services/30-june-2026
- **Direct URL**: https://files.digital.nhs.uk/B1/F5AC73/GPWPracticeCSV.062026.zip
- **Downloaded**: 2026-08-07
- **Vintage**: 30 June 2026 snapshot

## PCNWFIndividualCSV.062026.zip

- **Source**: NHS England Digital, "Primary Care Network Workforce"
  monthly publication — individual-level PCN-employed staff FTE
  https://digital.nhs.uk/data-and-information/publications/statistical/primary-care-network-workforce/30-june-2026
- **Direct URL**: https://files.digital.nhs.uk/A8/E524AA/PCNWFIndividualCSV.062026.zip
- **Downloaded**: 2026-08-07
- **Vintage**: 30 June 2026 snapshot

## qof-2425-prac-dom-ach.xlsx

- **Source**: NHS England Digital, "Quality and Outcomes Framework,
  2024-25" — practice-level overall achievement
  https://digital.nhs.uk/data-and-information/publications/statistical/quality-and-outcomes-framework-achievement-prevalence-and-exceptions-data/2024-25
- **Direct URL**: https://files.digital.nhs.uk/EB/16B1C0/qof-2425-prac-dom-ach.xlsx
- **Downloaded**: 2026-08-07
- **Vintage**: 2024-25 (Apr 2024 - Mar 2025), 6,196 practice rows incl. footer

## PREVALENCE_2425.csv

- **Source**: NHS England Digital, "Quality and Outcomes Framework,
  2024-25" raw data — practice-level disease register counts across 21
  chronic conditions (AF, AST, CAN, CHD, CKD, COPD, DEM, DEP, DM, EP, HF,
  HYP, LD, MH, NDH, OB, OST, PAD, PC, RA, STIA), each with its own
  correctly-scoped denominator
  https://digital.nhs.uk/data-and-information/publications/statistical/quality-and-outcomes-framework-achievement-prevalence-and-exceptions-data/2024-25
- **Direct URL**: https://files.digital.nhs.uk/95/4708D7/QOF2425.zip
  (only `PREVALENCE_2425.csv` extracted and kept — the zip also bundles
  8 large regional achievement files, ~94MB, not needed here)
- **Downloaded**: 2026-08-08
- **Vintage**: 2024-25 (Apr 2024 - Mar 2025)
- Used to build PPD's "disease prevalence" peer-group variable (see
  ref/CONCEPT.md) as the list-size-weighted mean register rate across
  all 21 conditions per PCN — this double-counts multimorbid patients,
  so it's a relative similarity index for clustering, not a clinical
  prevalence %, and is never published as a standalone figure.

## Known data-quality notes

- The mapping file carries a placeholder `PCN_CODE = "U"` / `PCN_NAME =
  "Unallocated"` for practices not yet assigned to a real PCN. It spans
  multiple ICBs, so a naive join attributes its patients to whichever ICB
  happens to appear first — `pcn_icb_lookup()` in `src/aggregate_pcn.R`
  explicitly excludes it.
- IMD 2025 (indicator 94240) is listed in Fingertips' indicator/area-type
  catalogue as available at PCN level, but empirically has no populated
  PCN-level rows — only GP-practice level actually has values. Fetched at
  practice level and aggregated to PCN ourselves (population-weighted).
- NHS Digital publications don't agree on ICB name strings (e.g. "NHS
  South East London Integrated Care Board" vs "NHS South East London
  ICB") — all joins in `src/aggregate_pcn.R` match on ICB/PCN **code**,
  never name.
- QOF's own embedded PCN attribution (2024-25 vintage) can be stale
  against the current ePCN mapping — three South East London practices
  were reassigned to a different PCN between the two. `pcn_qof()` always
  uses the current ePCN mapping's attribution, not QOF's own.
- Per CLAUDE.md, every source is collated at GP-practice level first and
  aggregated to PCN ourselves — even registration, which also publishes
  ready-made PCN-level rows — so a future report can drill down to
  practice level. Checked that this doesn't silently change the numbers:
  summing practice-level registration to PCN for the pilot ICB gives the
  same total (2,087,618 patients, 37 PCNs) as using the file's own PCN
  rows directly.
- A small number of PCNs straddle two ICBs (the ODS ePCN spec documents
  this explicitly — not a data error), e.g. U41591 "Coast and Country
  PCN" splits across Devon and Cornwall. This broke the "PCN_CODE is a
  unique key" assumption once aggregation went national for PPD (surfaced
  as a dplyr many-to-many join warning, not a silent wrong number).
  `pcn_primary_icb()` now assigns each PCN a single ICB — the one with
  the majority of its registered patients — for labelling/filtering only;
  every PCN's own totals (list size, FTE, etc.) still sum across all of
  its practices regardless of which ICB each one sits in.
