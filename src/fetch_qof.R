# QOF (Quality and Outcomes Framework) 2024-25, practice-level overall
# achievement (see ref/CONCEPT.md) — used as PPD's peer-comparison metric.

fetch_qof_practice_achievement <- function(dest_dir = "dat/in") {
  dir.create(dest_dir, showWarnings = FALSE, recursive = TRUE)
  xlsx_path <- file.path(dest_dir, "qof-2425-prac-dom-ach.xlsx")
  if (!file.exists(xlsx_path)) {
    utils::download.file(
      "https://files.digital.nhs.uk/EB/16B1C0/qof-2425-prac-dom-ach.xlsx",
      xlsx_path,
      mode = "wb", quiet = TRUE
    )
  }

  # Header spans rows 2-4 (merged cells); data starts row 5. Read
  # headerless and select by position rather than fight the merged header.
  d <- readxl::read_excel(
    xlsx_path,
    sheet = "Overall domain achievement",
    col_names = FALSE,
    skip = 4
  )
  out <- d[, c(4, 5, 6, 7, 9, 13)]
  names(out) <- c(
    "PCN_CODE", "PCN_NAME", "PRACTICE_CODE", "PRACTICE_NAME",
    "list_size_2425", "qof_achievement_pct_2425"
  )
  # Trailing blank/header rows in the sheet coerce to NA here — expected,
  # filtered out below.
  out$list_size_2425 <- suppressWarnings(as.numeric(out$list_size_2425))
  out$qof_achievement_pct_2425 <- suppressWarnings(as.numeric(out$qof_achievement_pct_2425))
  dplyr::filter(out, !is.na(PRACTICE_CODE))
}

# QOF disease-register prevalence, practice level — one of PPD's three
# peer-group variables (list size, IMD, prevalence — see ref/CONCEPT.md).
# Lives in NHS Digital's raw-data zip alongside 8 large regional
# achievement files we don't need; downloaded to a temp path and only
# PREVALENCE_2425.csv (3.6MB) is kept in dat/in, not the full 94MB zip.
fetch_qof_practice_prevalence <- function(dest_dir = "dat/in") {
  dir.create(dest_dir, showWarnings = FALSE, recursive = TRUE)
  csv_path <- file.path(dest_dir, "PREVALENCE_2425.csv")
  if (!file.exists(csv_path)) {
    tmp_zip <- tempfile(fileext = ".zip")
    utils::download.file(
      "https://files.digital.nhs.uk/95/4708D7/QOF2425.zip",
      tmp_zip,
      mode = "wb", quiet = TRUE
    )
    utils::unzip(tmp_zip, files = "PREVALENCE_2425.csv", exdir = dest_dir, junkpaths = TRUE)
    unlink(tmp_zip)
  }
  readr::read_csv(csv_path, show_col_types = FALSE)
}
