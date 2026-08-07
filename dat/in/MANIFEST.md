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

## IIF_indicators_annual_pub_2023_24.csv

- **Source**: NHS England Digital, "Network Contract DES (MI) - 2023/24
  IIF" — PCN and GP-practice level numerator/denominator by indicator
  https://digital.nhs.uk/data-and-information/publications/statistical/mi-network-contract-des/2023-24-iif
- **Direct URL**: https://files.digital.nhs.uk/C3/0F8B0D/IIF_indicators_annual_pub_2023_24.csv
- **Downloaded**: 2026-08-07
- **Vintage**: 2023/24 — the latest annual IIF file; IIF itself has since
  been slimmed to 2 indicators for 2024/25 (see ref/CONCEPT.md). Raw
  numerator/denominator only, no target thresholds or achievement %.

## Known data-quality notes

- The mapping file carries a placeholder `PCN_CODE = "U"` / `PCN_NAME =
  "Unallocated"` for practices not yet assigned to a real PCN. It spans
  multiple ICBs, so a naive join attributes its patients to whichever ICB
  happens to appear first — `pcn_list_size_for_icb()` in
  `src/aggregate_pcn.R` explicitly excludes it.
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
  were reassigned to a different PCN between the two. `pcn_qof_for_icb()`
  always uses the current ePCN mapping's attribution, not QOF's own.
