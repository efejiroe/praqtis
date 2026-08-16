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
  tar_target(practice_dna, fetch_practice_dna()),

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
  tar_target(
    national_practice_need_bands,
    practice_need_bands(practice_registration)
  ),
  tar_target(
    national_practice_imd_quintile,
    practice_imd_quintile(practice_imd, practice_registration)
  ),
  tar_target(
    national_pcn_composition,
    pcn_need_composition(
      national_practice_need_bands, national_practice_imd_quintile,
      national_pcn_list_size, epcn_mapping
    )
  ),

  # DNA rate + practice-level staffing snapshot — internal diagnostics
  # only (see CLAUDE.md): help investigate a flagged outlier PCN, or a
  # follow-up call, never rendered into report/pcn_report.qmd. Neither
  # feeds into national_staffing_model/national_staffing_funnel_flags —
  # DNA is plausibly a symptom of the same understaffing dynamics the
  # model already measures, so folding it in would risk circularity.
  tar_target(national_practice_dna_rate, practice_dna_rate(practice_dna)),
  tar_target(
    national_pcn_dna_rate,
    pcn_dna_rate(national_practice_dna_rate, epcn_mapping, national_pcn_primary_icb)
  ),
  tar_target(
    national_practice_staffing_snapshot,
    practice_staffing_snapshot(practice_registration, practice_gp_workforce)
  ),

  # National funnel-plot outlier check on staffing (see compute_funnel.R)
  # — the MVP's one scoring step. national_staffing_model is self-fitted
  # from our own national data (a Poisson rate regression on population
  # composition); national_model_comparison checks it against a published
  # external source without feeding into the funnel itself.
  tar_target(
    national_staffing_model,
    fit_staffing_model(national_pcn_composition, national_pcn_workforce)
  ),
  tar_target(
    national_staffing_funnel_flags,
    national_staffing_funnel(
      national_staffing_model, national_pcn_composition, national_pcn_workforce
    )
  ),
  tar_target(
    national_staffing_model_comparison,
    national_model_comparison(national_staffing_model, national_practice_need_bands)
  )
)
