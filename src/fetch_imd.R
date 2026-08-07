# Deprivation (IMD 2025, indicator 94240) via fingertipsR. Verified
# empirically that this indicator is NOT populated at PCN level in
# Fingertips despite the catalogue listing PCN as a linked area type —
# only GP-practice level (AreaTypeID 7) actually has values. Aggregate to
# PCN ourselves, population-weighted by list size (see aggregate_pcn.R).
#
# fingertipsR pulls live from an API rather than a static file, so the
# result is cached to dat/in as a snapshot for reproducibility, same as
# the other fetchers.

fetch_practice_imd <- function(dest_dir = "dat/in") {
  dir.create(dest_dir, showWarnings = FALSE, recursive = TRUE)
  csv_path <- file.path(dest_dir, "fingertips-imd-2025-gp-practice.csv")

  if (!file.exists(csv_path)) {
    d <- fingertipsR::fingertips_data(
      IndicatorID = 94240,
      AreaTypeID = 7,
      ParentAreaTypeID = 221
    )
    d <- d[d$AreaType == "GPs", c("AreaCode", "AreaName", "Timeperiod", "Value")]
    names(d) <- c("PRACTICE_CODE", "PRACTICE_NAME", "IMD_YEAR", "IMD_SCORE")
    readr::write_csv(d, csv_path)
  }

  readr::read_csv(csv_path, show_col_types = FALSE)
}
