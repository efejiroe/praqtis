# QOF (Quality and Outcomes Framework) 2024-25, practice-level overall
# achievement. TPG's primary source (see ref/CONCEPT.md) — QOF is the
# stable, well-populated indicator set; IIF is a minor supplement
# (fetch_iif.R) since it's been slimmed to 2 indicators for 2024/25.

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
