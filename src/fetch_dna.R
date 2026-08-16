# NHS England Digital GPAD "Appointments in General Practice" monthly
# publication, June 2026 snapshot. Source URL, download date and vintage
# recorded in dat/in/MANIFEST.md.
#
# The zip bundles three months (Apr/May/Jun 2026) of practice-level
# crosstabs — only June is read, for consistency with the June 2026
# vintage already used by fetch_practice_gp_workforce()/
# fetch_pcn_arrs_workforce(). Confirmed empirically (per CLAUDE.md):
# each row is one practice x HCP type x appointment mode x national
# category x booking-interval x status combination, with columns
# GP_CODE, COUNT_OF_APPOINTMENTS, APPT_STATUS ("Attended"/"DNA"/
# "Unknown"). The file also carries ready-made PCN_CODE/PCN_NAME columns,
# but per CLAUDE.md's collate-at-practice-level-first rule this is
# summed from GP_CODE and re-attributed to PCN via epcn_mapping like
# every other source, not taken from this file's own PCN labelling.
fetch_practice_dna <- function(dest_dir = "dat/in") {
  zip_path <- download_and_cache_zip(
    "https://files.digital.nhs.uk/36/FE673C/Practice_Level_Crosstab_Jun_26.zip",
    "Practice_Level_Crosstab_Jun_26.zip",
    dest_dir
  )
  csv_name <- "Practice_Level_Crosstab_Jun_26.csv"
  readr::read_csv(unz(zip_path, csv_name), show_col_types = FALSE) |>
    dplyr::filter(APPT_STATUS %in% c("Attended", "DNA")) |>
    dplyr::group_by(PRACTICE_CODE = GP_CODE, APPT_STATUS) |>
    dplyr::summarise(n = sum(COUNT_OF_APPOINTMENTS, na.rm = TRUE), .groups = "drop")
}
