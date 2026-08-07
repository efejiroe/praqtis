# IIF (Investment and Impact Fund) 2023/24. Minor supplement to TPG (see
# ref/CONCEPT.md) — this is the latest annual IIF publication; IIF itself
# has since been slimmed to 2 indicators for 2024/25, with the rest
# folded into the Capacity and Access Payment.
#
# Data is numerator/denominator pairs per indicator, not a ready
# percentage, and doesn't include the target thresholds (published
# separately as PDF guidance, not fetched here) — computing an
# achievement gap from this is Phase 2 modelling, not Phase 1 fetch.
#
# The file publishes both GP-practice and PCN rows, but not every
# indicator exists at both levels: some (the age-sex-standardised ACC-10
# rate) are calculated centrally and only ever published at PCN level —
# there is no practice-level figure to drill down to. Per CLAUDE.md's
# collate-at-GP-level rule, indicators available at practice level are
# fetched there and aggregated to PCN ourselves (aggregate_pcn.R);
# PCN-only indicators are used as-is, determined empirically (which
# IND_CODEs actually appear at practice level) rather than hardcoded.

download_iif_csv <- function(dest_dir = "dat/in") {
  dir.create(dest_dir, showWarnings = FALSE, recursive = TRUE)
  csv_path <- file.path(dest_dir, "IIF_indicators_annual_pub_2023_24.csv")
  if (!file.exists(csv_path)) {
    utils::download.file(
      "https://files.digital.nhs.uk/C3/0F8B0D/IIF_indicators_annual_pub_2023_24.csv",
      csv_path,
      mode = "wb", quiet = TRUE
    )
  }
  readr::read_csv(csv_path, show_col_types = FALSE)
}

fetch_practice_iif_indicators <- function(dest_dir = "dat/in") {
  download_iif_csv(dest_dir) |>
    dplyr::filter(ORGANISATION_TYPE == "GP practice") |>
    dplyr::rename(PRACTICE_CODE = ORGANISATION_CODE, PRACTICE_NAME = ORGANISATION_NAME)
}

fetch_pcn_native_iif_indicators <- function(dest_dir = "dat/in") {
  raw <- download_iif_csv(dest_dir)
  practice_ind_codes <- unique(raw$IND_CODE[raw$ORGANISATION_TYPE == "GP practice"])
  raw |>
    dplyr::filter(ORGANISATION_TYPE == "PCN", !IND_CODE %in% practice_ind_codes) |>
    dplyr::rename(PCN_CODE = ORGANISATION_CODE, PCN_NAME = ORGANISATION_NAME)
}
