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
# term in the ROS denominator (see ref/CONCEPT.md).
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

# PCN-employed staff FTE, individual-level. PCNs directly employ almost
# exclusively ARRS-funded roles, so this is the "ARRS FTE already in post"
# term in the ROS denominator — see the corrected formula note in
# ref/CONCEPT.md (no PCN-level ARRS *spend* is publicly available, only
# FTE/headcount).
fetch_pcn_arrs_workforce <- function(dest_dir = "dat/in") {
  zip_path <- download_and_cache_zip(
    "https://files.digital.nhs.uk/A8/E524AA/PCNWFIndividualCSV.062026.zip",
    "PCNWFIndividualCSV.062026.zip",
    dest_dir
  )
  csv_name <- "1.Primary Care Networks - June 2026 Individual Level.csv"
  readr::read_csv(unz(zip_path, csv_name), show_col_types = FALSE) |>
    dplyr::group_by(PCN_CODE, ICB_CODE) |>
    dplyr::summarise(arrs_fte = sum(FTE, na.rm = TRUE), .groups = "drop")
}
