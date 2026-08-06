# NHS England Digital "Patients Registered at a GP Practice" monthly
# publication — GP-practice/PCN registered-patient counts, and the ePCN
# mapping (practice -> PCN -> sub-ICB -> ICB). Source URLs, download date
# and vintage are recorded in dat/in/MANIFEST.md.

# Downloads the zip snapshot into dat/in (the committed public snapshot)
# and reads the CSV straight out of it — the extracted CSV is never
# written to disk, so dat/in only ever holds the small original download.
read_gp_reg_zip <- function(url, zip_name, dest_dir = "dat/in") {
  dir.create(dest_dir, showWarnings = FALSE, recursive = TRUE)
  zip_path <- file.path(dest_dir, zip_name)
  if (!file.exists(zip_path)) {
    utils::download.file(url, zip_path, mode = "wb", quiet = TRUE)
  }
  csv_name <- utils::unzip(zip_path, list = TRUE)$Name[1]
  readr::read_csv(unz(zip_path, csv_name), show_col_types = FALSE)
}

fetch_epcn_mapping <- function(dest_dir = "dat/in") {
  read_gp_reg_zip(
    "https://files.digital.nhs.uk/98/8142DB/gp-reg-pat-prac-map.zip",
    "gp-reg-pat-prac-map.zip",
    dest_dir
  )
}

fetch_gp_registration_pcn <- function(dest_dir = "dat/in") {
  read_gp_reg_zip(
    "https://files.digital.nhs.uk/BB/362F1A/gp-reg-pat-prac-quin-age.zip",
    "gp-reg-pat-prac-quin-age.zip",
    dest_dir
  ) |>
    dplyr::filter(ORG_TYPE == "PCN")
}
