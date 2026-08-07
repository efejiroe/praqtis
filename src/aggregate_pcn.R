# Aggregate each raw data source to PCN level for one ICB. No ROS/TPG/PPD
# scoring here — combining these into the actual metrics is Phase 2 (see
# CLAUDE.md roadmap); this is just fetch-and-pool-to-PCN.
#
# ICBs are matched by ICB_CODE, not ICB_NAME — NHS Digital publications
# don't agree on the name string (the ePCN mapping says "NHS South East
# London Integrated Care Board", the PCN Workforce file says "NHS South
# East London ICB"), but the ODS code (e.g. "QKK") is consistent
# everywhere.

pcn_icb_lookup <- function(epcn_mapping) {
  # PCN_CODE "U" / PCN_NAME "Unallocated" is a placeholder spanning every
  # ICB (practices not yet assigned to a real PCN) — not a genuine PCN.
  epcn_mapping |>
    dplyr::filter(!is.na(PCN_CODE), PCN_NAME != "Unallocated") |>
    dplyr::distinct(PRACTICE_CODE, PCN_CODE, PCN_NAME, ICB_CODE, ICB_NAME)
}

pcn_list_size_for_icb <- function(pcn_registration, epcn_mapping, icb_code) {
  pcn_icb <- pcn_icb_lookup(epcn_mapping) |>
    dplyr::distinct(PCN_CODE, PCN_NAME, ICB_CODE, ICB_NAME)

  pcn_registration |>
    dplyr::filter(SEX == "ALL", AGE_GROUP_5 == "ALL") |>
    dplyr::select(PCN_CODE = ORG_CODE, list_size = NUMBER_OF_PATIENTS) |>
    dplyr::inner_join(pcn_icb, by = "PCN_CODE") |>
    dplyr::filter(ICB_CODE == icb_code) |>
    dplyr::arrange(dplyr::desc(list_size))
}

# Population-weighted mean IMD score per PCN (IMD is only published at
# practice level — see fetch_imd.R — so PCN figures have to be built, not
# fetched ready-made).
pcn_imd_for_icb <- function(practice_imd, practice_registration, epcn_mapping, icb_code) {
  practice_list_size <- practice_registration |>
    dplyr::filter(SEX == "ALL", AGE_GROUP_5 == "ALL") |>
    dplyr::select(PRACTICE_CODE = ORG_CODE, list_size = NUMBER_OF_PATIENTS)

  pcn_icb_lookup(epcn_mapping) |>
    dplyr::filter(ICB_CODE == icb_code) |>
    dplyr::inner_join(practice_imd, by = "PRACTICE_CODE") |>
    dplyr::inner_join(practice_list_size, by = "PRACTICE_CODE") |>
    dplyr::group_by(PCN_CODE, PCN_NAME) |>
    dplyr::summarise(
      imd_score = stats::weighted.mean(IMD_SCORE, list_size, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::arrange(PCN_CODE)
}

# Practice-level GP+DPC FTE summed to PCN, alongside PCN-employed (mostly
# ARRS) FTE — the two raw ingredients of the ROS denominator, not yet
# combined into ROS itself.
pcn_workforce_for_icb <- function(practice_gp_workforce, pcn_arrs_workforce, epcn_mapping, icb_code) {
  practice_fte_by_pcn <- pcn_icb_lookup(epcn_mapping) |>
    dplyr::filter(ICB_CODE == icb_code) |>
    dplyr::inner_join(practice_gp_workforce, by = "PRACTICE_CODE") |>
    dplyr::group_by(PCN_CODE, PCN_NAME) |>
    dplyr::summarise(practice_fte = sum(practice_fte, na.rm = TRUE), .groups = "drop")

  practice_fte_by_pcn |>
    dplyr::left_join(
      dplyr::filter(pcn_arrs_workforce, ICB_CODE == icb_code) |>
        dplyr::select(PCN_CODE, arrs_fte),
      by = "PCN_CODE"
    ) |>
    dplyr::arrange(PCN_CODE)
}

# List-size-weighted mean QOF overall achievement % per PCN.
pcn_qof_for_icb <- function(qof_practice_achievement, epcn_mapping, icb_code) {
  practice_icb <- pcn_icb_lookup(epcn_mapping) |>
    dplyr::filter(ICB_CODE == icb_code) |>
    dplyr::distinct(PRACTICE_CODE, PCN_CODE, PCN_NAME)

  # QOF's own embedded PCN_CODE/PCN_NAME reflect the 2024-25 QOF vintage,
  # which can be a year+ stale vs the current ePCN mapping (practices do
  # get reassigned between PCNs) — drop them and use the mapping's
  # current attribution instead, so every metric agrees on what a PCN is.
  qof_practice_achievement |>
    dplyr::select(-PCN_CODE, -PCN_NAME) |>
    dplyr::inner_join(practice_icb, by = "PRACTICE_CODE") |>
    dplyr::group_by(PCN_CODE, PCN_NAME) |>
    dplyr::summarise(
      qof_achievement_pct = stats::weighted.mean(
        qof_achievement_pct_2425, list_size_2425, na.rm = TRUE
      ),
      .groups = "drop"
    ) |>
    dplyr::arrange(PCN_CODE)
}

# IIF is already published at PCN level (see fetch_iif.R) — just filter to
# the ICB, no aggregation needed. Numerator/denominator ratios and target
# thresholds are Phase 2.
pcn_iif_for_icb <- function(pcn_iif_indicators, epcn_mapping, icb_code) {
  pcn_icb <- pcn_icb_lookup(epcn_mapping) |>
    dplyr::filter(ICB_CODE == icb_code) |>
    dplyr::distinct(PCN_CODE)

  pcn_iif_indicators |>
    dplyr::inner_join(pcn_icb, by = "PCN_CODE") |>
    dplyr::arrange(PCN_CODE, IND_CODE)
}
