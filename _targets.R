library(targets)

tar_option_set(packages = c("readr", "dplyr", "fingertipsR", "tibble", "FunnelPlotR"))

for (f in list.files("src", full.names = TRUE)) source(f)

list(
  # Fetch
  tar_target(epcn_mapping, fetch_epcn_mapping()),
  tar_target(practice_registration, fetch_gp_registration_practice()),
  tar_target(practice_imd, fetch_practice_imd()),
  tar_target(practice_gp_workforce, fetch_practice_gp_workforce()),
  tar_target(pcn_arrs_workforce, fetch_pcn_arrs_workforce()),

  # Aggregate to PCN, nationally — the funnel plot's control limits need
  # every PCN in England, not a single ICB, to reflect the true national
  # spread of staffing intensity.
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
    national_pcn_workforce,
    pcn_workforce(
      practice_gp_workforce, pcn_arrs_workforce, epcn_mapping, national_pcn_primary_icb
    )
  ),

  # National funnel-plot outlier check on ROS's staffing ratio (see
  # compute_ros.R) — the MVP's one scoring step.
  tar_target(
    national_pcn_ros_funnel_flags,
    national_pcn_ros_funnel(national_pcn_list_size, national_pcn_imd, national_pcn_workforce)
  )
)
