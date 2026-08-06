library(targets)

tar_option_set(packages = c("readr", "dplyr"))

for (f in list.files("src", full.names = TRUE)) source(f)

# Placeholder pilot ICB for Phase 1 — swap for the ICB with a real contact
# once Phase 4 identifies one (see CLAUDE.md roadmap).
pilot_icb <- "NHS North East and North Cumbria Integrated Care Board"

list(
  tar_target(epcn_mapping, fetch_epcn_mapping()),
  tar_target(pcn_registration, fetch_gp_registration_pcn()),
  tar_target(
    pilot_pcn_list_size,
    pcn_list_size_for_icb(pcn_registration, epcn_mapping, pilot_icb)
  )
)
