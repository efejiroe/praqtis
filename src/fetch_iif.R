# IIF (Investment and Impact Fund) 2023/24, PCN-level. Minor supplement to
# TPG (see ref/CONCEPT.md) — this is the latest annual IIF publication;
# IIF itself has since been slimmed to 2 indicators for 2024/25, with the
# rest folded into the Capacity and Access Payment.
#
# Data is numerator/denominator pairs per indicator, not a ready
# percentage, and doesn't include the target thresholds (published
# separately as PDF guidance, not fetched here) — computing an
# achievement gap from this is Phase 2 modelling, not Phase 1 fetch.

fetch_pcn_iif_indicators <- function(dest_dir = "dat/in") {
  dir.create(dest_dir, showWarnings = FALSE, recursive = TRUE)
  csv_path <- file.path(dest_dir, "IIF_indicators_annual_pub_2023_24.csv")
  if (!file.exists(csv_path)) {
    utils::download.file(
      "https://files.digital.nhs.uk/C3/0F8B0D/IIF_indicators_annual_pub_2023_24.csv",
      csv_path,
      mode = "wb", quiet = TRUE
    )
  }
  readr::read_csv(csv_path, show_col_types = FALSE) |>
    dplyr::filter(ORGANISATION_TYPE == "PCN") |>
    dplyr::rename(PCN_CODE = ORGANISATION_CODE, PCN_NAME = ORGANISATION_NAME)
}
