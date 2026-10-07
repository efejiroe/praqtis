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

## arrs_roles.csv

- **Source**: hand-built lookup, mapping each PCN Workforce `STAFF_ROLE` /
  `DETAILED_STAFF_ROLE` to ARRS-reimbursable or not, from NHS England,
  "Network Contract DES: Contract specification 2026/27 – PCN requirements
  and entitlements" (publication reference PRN02483): Table 2 (maximum
  reimbursement per role), sections 7.3.2–7.3.9 and Annex B
  https://www.england.nhs.uk/wp-content/uploads/2026/03/network-contract-des-contract-specification-2026-27.pdf
- **Downloaded**: 2026-10-07 (specification read and the mapping made that day)
- **Vintage**: 2026/27 contract year (1 April 2026 – 31 March 2027)
- **Rules**: a role is ARRS only if the specification names it (`spec_ref`
  column cites where). Clinical Directors are paid from Core PCN Funding
  (Table 1), so are not ARRS. Roles fundable only with commissioner
  agreement (7.3.2-A/C, e.g. managers, admin, "other" nurses) are not
  counted, because no public source records which posts were agreed.
  Roles missing from the CSV count as not ARRS — re-check the CSV against
  any new PCN Workforce vintage for new role names.

## Practice_Level_Crosstab_Jun_26.zip

- **Source**: NHS England Digital, "Appointments in General Practice"
  (GPAD) monthly publication — practice-level appointment status
  crosstab (HCP type / national category / mode / status / booking
  interval)
  https://digital.nhs.uk/data-and-information/publications/statistical/appointments-in-general-practice/june-2026
- **Direct URL**: https://files.digital.nhs.uk/36/FE673C/Practice_Level_Crosstab_Jun_26.zip
- **Downloaded**: 2026-08-16
- **Vintage**: June 2026 snapshot. The zip also bundles April and May
  2026 crosstabs (same publication, three-month rolling window) — only
  June is read, for consistency with the workforce/registration sources'
  own June 2026 vintage.

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
  unique key" assumption once aggregation went national (surfaced as a
  dplyr many-to-many join warning, not a silent wrong number).
  `pcn_primary_icb()` now assigns each PCN a single ICB — the one with
  the majority of its registered patients — for labelling/filtering only;
  every PCN's own totals (list size, FTE, etc.) still sum across all of
  its practices regardless of which ICB each one sits in.
- GPAD's crosstab uses `GP_CODE` for the practice-code column (not
  `PRACTICE_CODE`/`PRAC_CODE` as in other sources) — another instance of
  the "NHS Digital publications don't agree on column names" lesson
  above. `APPT_STATUS` takes exactly three values: `Attended`, `DNA`,
  `Unknown` — `Unknown` is excluded from the DNA-rate denominator
  (neither a confirmed attendance nor a confirmed non-attendance). 23 of
  6,139 practices in the registration file have no matching row in the
  DNA data (no recorded appointment activity that month) — left as
  missing, not coalesced to zero, consistent with `arrs_fte_missing`'s
  precedent elsewhere in this pipeline.
- 26 ePCN-mapped practices (66,330 registered patients, June 2026) are
  either absent from the practice workforce file or report exactly 0 GP +
  Direct Patient Care FTE. This used to remove those practices from the
  staffing funnel; since the funnel became ARRS-only (2026-10-07) it no
  longer matters, because ARRS staff serve the whole PCN and practice
  returns aren't counted. Still relevant to the internal practice
  drill-down (`practice_staffing_snapshot()`'s `fte_reported` flag).
- 27 PCNs have no rows in the PCN Workforce (ARRS) file. All 27 codes
  exist in the ePCN mapping, so this isn't a code mismatch — but the
  file can't distinguish "no ARRS staff" from "not submitted". These
  PCNs are excluded from the funnel (`pcn_staffing_data()` in
  `src/compute_funnel.R`) rather than treated as zero ARRS FTE, which
  had made them look strongly understaffed purely because of missing data.
- 5 PCNs filed a PCN Workforce return listing no ARRS-eligible roles —
  only a Clinical Director and/or admin — while their populations predict
  9–32 ARRS FTE (June 2026). Read as ARRS staff recorded elsewhere (e.g.
  under a lead practice), not as none, so they are excluded alongside the
  no-return PCNs. North Lewisham PCN (U53896) reports ARRS staff but no
  pharmacists or pharmacy technicians, and its practices' own pharmacy
  rows are blank — possibly the same issue for one role; not excluded,
  but not used as a report example either.
