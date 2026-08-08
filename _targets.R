library(targets)

tar_option_set(packages = c("readr", "dplyr", "readxl", "fingertipsR"))

for (f in list.files("src", full.names = TRUE)) source(f)

# Pilot ICB for Phase 1 — chosen because the pilot contact sits in this
# ICB's patch (see CLAUDE.md roadmap, Phase 4). Matched by ODS code, not
# name — NHS Digital publications don't agree on the ICB name string.
pilot_icb_code <- "QKK" # NHS South East London Integrated Care Board

list(
  # Fetch
  tar_target(epcn_mapping, fetch_epcn_mapping()),
  tar_target(practice_registration, fetch_gp_registration_practice()),
  tar_target(practice_imd, fetch_practice_imd()),
  tar_target(practice_gp_workforce, fetch_practice_gp_workforce()),
  tar_target(pcn_arrs_workforce, fetch_pcn_arrs_workforce()),
  tar_target(qof_practice_achievement, fetch_qof_practice_achievement()),
  tar_target(practice_iif_indicators, fetch_practice_iif_indicators()),
  tar_target(pcn_native_iif_indicators, fetch_pcn_native_iif_indicators()),

  # Aggregate to PCN, for the pilot ICB (no modelling yet — Phase 2)
  tar_target(
    pilot_pcn_list_size,
    pcn_list_size_for_icb(practice_registration, epcn_mapping, pilot_icb_code)
  ),
  tar_target(
    pilot_pcn_imd,
    pcn_imd_for_icb(practice_imd, practice_registration, epcn_mapping, pilot_icb_code)
  ),
  tar_target(
    pilot_pcn_workforce,
    pcn_workforce_for_icb(practice_gp_workforce, pcn_arrs_workforce, epcn_mapping, pilot_icb_code)
  ),
  tar_target(
    pilot_pcn_qof,
    pcn_qof_for_icb(qof_practice_achievement, epcn_mapping, pilot_icb_code)
  ),
  tar_target(
    pilot_pcn_iif,
    pcn_iif_for_icb(
      practice_iif_indicators, pcn_native_iif_indicators, epcn_mapping, pilot_icb_code
    )
  ),

  # Phase 2 — score (still no PPD/TPG here: PPD needs a national peer
  # group, TPG needs target thresholds from guidance PDFs — see
  # CLAUDE.md roadmap)
  tar_target(
    pilot_pcn_ros,
    pcn_ros(pilot_pcn_list_size, pilot_pcn_imd, pilot_pcn_workforce)
  )
)
