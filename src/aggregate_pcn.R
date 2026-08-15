# Aggregate each raw data source to PCN level, nationally — no ROS
# scoring here (that's compute_ros.R and Phase 2 more broadly); this is
# just fetch-and-pool-to-PCN. Built at national scale, not pre-filtered
# to one ICB, because PPD's peer group (compute_ppd.R) needs every PCN
# in England to find genuine neighbours — filter_pcn_icb() below is the
# thin final step for pilot-ICB-only views.
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

# A handful of PCNs straddle two ICBs (a known NHS organisational fact —
# the ODS ePCN spec explicitly documents "PCNs cross CCG boundaries" —
# not a data error; e.g. U41591 "Coast and Country PCN" splits across
# Devon and Cornwall). Every PCN-level table below needs PCN_CODE to be a
# clean unique key, so each PCN is assigned a single "primary" ICB — the
# one holding the majority of its registered patients — for labelling
# and filter_pcn_icb() only. The PCN's own totals (list size, FTE, etc.)
# still sum every one of its practices regardless of which ICB that
# practice individually sits in.
pcn_primary_icb <- function(practice_registration, epcn_mapping) {
  practice_list_size <- practice_registration |>
    dplyr::filter(SEX == "ALL", AGE_GROUP_5 == "ALL") |>
    dplyr::select(PRACTICE_CODE = ORG_CODE, list_size = NUMBER_OF_PATIENTS)

  pcn_icb_lookup(epcn_mapping) |>
    dplyr::inner_join(practice_list_size, by = "PRACTICE_CODE") |>
    dplyr::group_by(PCN_CODE, PCN_NAME, ICB_CODE, ICB_NAME) |>
    dplyr::summarise(icb_list_size = sum(list_size, na.rm = TRUE), .groups = "drop") |>
    dplyr::group_by(PCN_CODE) |>
    dplyr::slice_max(icb_list_size, n = 1, with_ties = FALSE) |>
    dplyr::ungroup() |>
    dplyr::select(PCN_CODE, PCN_NAME, ICB_CODE, ICB_NAME)
}

filter_pcn_icb <- function(pcn_table, icb_code) {
  dplyr::filter(pcn_table, ICB_CODE == icb_code)
}

# The registration file also publishes ready-made PCN-level totals, but
# per CLAUDE.md's collate-at-GP-level rule we sum practice-level list
# sizes ourselves so practice-level drill-down stays possible.
pcn_list_size <- function(practice_registration, epcn_mapping, primary_icb) {
  practice_list_size <- practice_registration |>
    dplyr::filter(SEX == "ALL", AGE_GROUP_5 == "ALL") |>
    dplyr::select(PRACTICE_CODE = ORG_CODE, list_size = NUMBER_OF_PATIENTS)

  pcn_icb_lookup(epcn_mapping) |>
    dplyr::distinct(PRACTICE_CODE, PCN_CODE, PCN_NAME) |>
    dplyr::inner_join(practice_list_size, by = "PRACTICE_CODE") |>
    dplyr::group_by(PCN_CODE, PCN_NAME) |>
    dplyr::summarise(list_size = sum(list_size, na.rm = TRUE), .groups = "drop") |>
    dplyr::inner_join(primary_icb, by = c("PCN_CODE", "PCN_NAME")) |>
    dplyr::arrange(dplyr::desc(list_size))
}

# Population-weighted mean IMD score per PCN (IMD is only published at
# practice level — see fetch_imd.R — so PCN figures have to be built, not
# fetched ready-made).
pcn_imd <- function(practice_imd, practice_registration, epcn_mapping, primary_icb) {
  practice_list_size <- practice_registration |>
    dplyr::filter(SEX == "ALL", AGE_GROUP_5 == "ALL") |>
    dplyr::select(PRACTICE_CODE = ORG_CODE, list_size = NUMBER_OF_PATIENTS)

  pcn_icb_lookup(epcn_mapping) |>
    dplyr::distinct(PRACTICE_CODE, PCN_CODE, PCN_NAME) |>
    dplyr::inner_join(practice_imd, by = "PRACTICE_CODE") |>
    dplyr::inner_join(practice_list_size, by = "PRACTICE_CODE") |>
    dplyr::group_by(PCN_CODE, PCN_NAME) |>
    dplyr::summarise(
      imd_score = stats::weighted.mean(IMD_SCORE, list_size, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::inner_join(dplyr::select(primary_icb, PCN_CODE, ICB_CODE), by = "PCN_CODE") |>
    dplyr::arrange(PCN_CODE)
}

# List-size-weighted mean prevalence rate per PCN, averaged across QOF's
# 21 chronic-disease registers (see fetch_qof.R). This double-counts
# multimorbid patients across registers, so it isn't a clinical
# prevalence % — it's a relative "how much registered chronic illness
# does this population carry" index, used only to compare PCNs against
# each other for the peer group (compute_ppd.R), never published as a
# standalone figure.
pcn_prevalence <- function(qof_practice_prevalence, practice_registration, epcn_mapping, primary_icb) {
  practice_list_size <- practice_registration |>
    dplyr::filter(SEX == "ALL", AGE_GROUP_5 == "ALL") |>
    dplyr::select(PRACTICE_CODE = ORG_CODE, list_size = NUMBER_OF_PATIENTS)

  practice_index <- qof_practice_prevalence |>
    dplyr::mutate(rate = REGISTER / PRACTICE_LIST_SIZE) |>
    dplyr::group_by(PRACTICE_CODE) |>
    dplyr::summarise(prevalence_index = mean(rate, na.rm = TRUE), .groups = "drop")

  pcn_icb_lookup(epcn_mapping) |>
    dplyr::distinct(PRACTICE_CODE, PCN_CODE, PCN_NAME) |>
    dplyr::inner_join(practice_index, by = "PRACTICE_CODE") |>
    dplyr::inner_join(practice_list_size, by = "PRACTICE_CODE") |>
    dplyr::group_by(PCN_CODE, PCN_NAME) |>
    dplyr::summarise(
      prevalence_index = stats::weighted.mean(prevalence_index, list_size, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::inner_join(dplyr::select(primary_icb, PCN_CODE, ICB_CODE), by = "PCN_CODE") |>
    dplyr::arrange(PCN_CODE)
}

# Practice-level GP+DPC FTE summed to PCN, alongside PCN-employed (mostly
# ARRS) FTE — the two raw ingredients of the ROS denominator, not yet
# combined into ROS itself.
pcn_workforce <- function(practice_gp_workforce, pcn_arrs_workforce, epcn_mapping, primary_icb) {
  practice_fte_by_pcn <- pcn_icb_lookup(epcn_mapping) |>
    dplyr::distinct(PRACTICE_CODE, PCN_CODE, PCN_NAME) |>
    dplyr::inner_join(practice_gp_workforce, by = "PRACTICE_CODE") |>
    dplyr::group_by(PCN_CODE, PCN_NAME) |>
    dplyr::summarise(practice_fte = sum(practice_fte, na.rm = TRUE), .groups = "drop")

  practice_fte_by_pcn |>
    dplyr::left_join(
      dplyr::select(pcn_arrs_workforce, PCN_CODE, arrs_fte),
      by = "PCN_CODE"
    ) |>
    dplyr::inner_join(dplyr::select(primary_icb, PCN_CODE, ICB_CODE), by = "PCN_CODE") |>
    dplyr::arrange(PCN_CODE)
}

# List-size-weighted mean QOF overall achievement % per PCN.
pcn_qof <- function(qof_practice_achievement, epcn_mapping, primary_icb) {
  practice_icb <- pcn_icb_lookup(epcn_mapping) |>
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
    dplyr::inner_join(dplyr::select(primary_icb, PCN_CODE, ICB_CODE), by = "PCN_CODE") |>
    dplyr::arrange(PCN_CODE)
}
