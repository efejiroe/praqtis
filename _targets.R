library(targets)

tar_option_set(packages = c("readr", "dplyr"))

for (f in list.files("src", full.names = TRUE)) source(f)

# Pilot ICB for Phase 1 — chosen because the pilot contact sits in this
# ICB's patch (see CLAUDE.md roadmap, Phase 4).
pilot_icb <- "NHS South East London Integrated Care Board"

list(
  tar_target(epcn_mapping, fetch_epcn_mapping()),
  tar_target(pcn_registration, fetch_gp_registration_pcn()),
  tar_target(
    pilot_pcn_list_size,
    pcn_list_size_for_icb(pcn_registration, epcn_mapping, pilot_icb)
  )
)
