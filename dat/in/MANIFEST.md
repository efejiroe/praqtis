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

## Known data-quality note

The mapping file carries a placeholder `PCN_CODE = "U"` / `PCN_NAME =
"Unallocated"` for practices not yet assigned to a real PCN. It spans
multiple ICBs, so a naive join attributes its patients to whichever ICB
happens to appear first — `pcn_list_size_for_icb()` in
`src/aggregate_pcn.R` explicitly excludes it.
