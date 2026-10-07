# NHS England Digital workforce publications, June 2026 snapshot.
# Source URLs, download date and vintage are recorded in dat/in/MANIFEST.md.

download_and_cache_zip <- function(url, zip_name, dest_dir = "dat/in") {
  dir.create(dest_dir, showWarnings = FALSE, recursive = TRUE)
  zip_path <- file.path(dest_dir, zip_name)
  if (!file.exists(zip_path)) {
    utils::download.file(url, zip_path, mode = "wb", quiet = TRUE)
  }
  zip_path
}

# Practice-level GP + Direct Patient Care FTE — the "Total Practice FTE"
# term in the staffing funnel check's actual-FTE figure (see ref/concept_note.md).
fetch_practice_gp_workforce <- function(dest_dir = "dat/in") {
  zip_path <- download_and_cache_zip(
    "https://files.digital.nhs.uk/B1/F5AC73/GPWPracticeCSV.062026.zip",
    "GPWPracticeCSV.062026.zip",
    dest_dir
  )
  csv_name <- "3 General Practice – June 2026 Practice Level - High level.csv"
  readr::read_csv(unz(zip_path, csv_name), show_col_types = FALSE) |>
    dplyr::filter(STAFF_GROUP %in% c("GP", "Direct Patient Care"), MEASURE == "FTE") |>
    dplyr::group_by(PRACTICE_CODE = PRAC_CODE) |>
    dplyr::summarise(practice_fte = sum(VALUE, na.rm = TRUE), .groups = "drop")
}

# PCN-employed staff FTE by role, from the individual-level PCN Workforce
# file. This is EVERY role a PCN employs — Clinical Directors, managers
# and admin as well as ARRS roles — so it's kept at role level here and
# filtered to ARRS-eligible roles downstream (aggregate_pcn.R::
# pcn_arrs_role_fte(), using read_arrs_roles() below). Summing it whole,
# as an earlier version did, overstated ARRS FTE. No PCN-level ARRS
# *spend* is publicly available, only FTE/headcount.
fetch_pcn_workforce_roles <- function(dest_dir = "dat/in") {
  zip_path <- download_and_cache_zip(
    "https://files.digital.nhs.uk/A8/E524AA/PCNWFIndividualCSV.062026.zip",
    "PCNWFIndividualCSV.062026.zip",
    dest_dir
  )
  csv_name <- "1.Primary Care Networks - June 2026 Individual Level.csv"
  readr::read_csv(unz(zip_path, csv_name), show_col_types = FALSE) |>
    dplyr::group_by(PCN_CODE, ICB_CODE, STAFF_ROLE, DETAILED_STAFF_ROLE) |>
    dplyr::summarise(fte = sum(FTE, na.rm = TRUE), .groups = "drop")
}

# Which PCN Workforce roles ARRS can reimburse, mapped by hand from NHS
# England's Network Contract DES specification 2026/27 (PRN02483: Table 2,
# sections 7.3.3-7.3.9 and Annex B) — see dat/in/MANIFEST.md. Only roles
# the specification names are TRUE. Roles a PCN can fund through ARRS
# only with its commissioner's agreement (7.3.2-A/C: e.g. managers,
# admin, "other" nurses) are left out, because no public source records
# which of those posts were agreed. Roles absent from the CSV count as
# not ARRS. Keyed on STAFF_ROLE + DETAILED_STAFF_ROLE because some roles
# (Therapists, Apprentices, Salaried GPs) split into ARRS and non-ARRS
# at the detailed level.
read_arrs_roles <- function(path) {
  readr::read_csv(path, show_col_types = FALSE) |>
    dplyr::filter(is_arrs) |>
    dplyr::select(STAFF_ROLE, DETAILED_STAFF_ROLE, report_role)
}
