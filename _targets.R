library(targets)

tar_option_set(packages = c("readr", "dplyr", "readxl", "fingertipsR", "tibble", "FunnelPlotR"))

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
  tar_target(qof_practice_prevalence, fetch_qof_practice_prevalence()),

  # Aggregate to PCN, nationally (no modelling yet) — needed at national
  # scale because PPD's peer group has to search all of England, not
  # just the pilot ICB
  tar_target(
    national_pcn_primary_icb,
    pcn_primary_icb(practice_registration, epcn_mapping)
  ),
  tar_target(
    national_pcn_list_size,
    pcn_list_size(practice_registration, epcn_mapping, national_pcn_primary_icb)
  ),
  tar_target(
    national_pcn_imd,
    pcn_imd(practice_imd, practice_registration, epcn_mapping, national_pcn_primary_icb)
  ),
  tar_target(
    national_pcn_prevalence,
    pcn_prevalence(
      qof_practice_prevalence, practice_registration, epcn_mapping, national_pcn_primary_icb
    )
  ),
  tar_target(
    national_pcn_workforce,
    pcn_workforce(
      practice_gp_workforce, pcn_arrs_workforce, epcn_mapping, national_pcn_primary_icb
    )
  ),
  tar_target(
    national_pcn_qof,
    pcn_qof(qof_practice_achievement, epcn_mapping, national_pcn_primary_icb)
  ),

  # Pilot ICB view — thin filter of the national tables
  tar_target(pilot_pcn_list_size, filter_pcn_icb(national_pcn_list_size, pilot_icb_code)),
  tar_target(pilot_pcn_imd, filter_pcn_icb(national_pcn_imd, pilot_icb_code)),
  tar_target(pilot_pcn_workforce, filter_pcn_icb(national_pcn_workforce, pilot_icb_code)),
  tar_target(pilot_pcn_qof, filter_pcn_icb(national_pcn_qof, pilot_icb_code)),

  # Phase 2 — score. ROS is the lead metric, checked for statistical
  # outliers via a national funnel plot (see compute_ros.R); PPD is the
  # corroborating peer-group signal.
  tar_target(
    pilot_pcn_ros,
    pcn_ros(pilot_pcn_list_size, pilot_pcn_imd, pilot_pcn_workforce)
  ),
  tar_target(
    national_pcn_ros_funnel_flags,
    national_pcn_ros_funnel(national_pcn_list_size, national_pcn_imd, national_pcn_workforce)
  ),
  tar_target(
    pilot_pcn_ros_funnel,
    filter_pcn_icb(national_pcn_ros_funnel_flags, pilot_icb_code)
  ),
  tar_target(
    national_features,
    national_pcn_features(national_pcn_list_size, national_pcn_imd, national_pcn_prevalence)
  ),
  tar_target(
    pilot_pcn_ppd,
    pcn_ppd_for_pcns(
      national_features, national_pcn_qof, pilot_pcn_list_size$PCN_CODE, k = 10
    )
  ),

  # Practice drill-down example — Nexus Health Group, North Southwark
  # PCN, surfaced while investigating that PCN's PPD gap. Registered as
  # a target (not just an interactive query) so it's reproducible and
  # available to the Phase 3 report.
  tar_target(
    nexus_practice_snapshot,
    practice_vs_pcn(
      practice_snapshot(
        "G85034", practice_registration, practice_imd, practice_gp_workforce,
        qof_practice_achievement, epcn_mapping
      ),
      pilot_pcn_qof, pilot_pcn_workforce, pilot_pcn_list_size
    )
  )
)
