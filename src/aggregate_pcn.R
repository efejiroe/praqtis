# Aggregate each raw data source to PCN level, nationally — no scoring
# here (that's compute_funnel.R); this is just fetch-and-pool-to-PCN.
# Built at national scale, not pre-filtered to one ICB, because the
# staffing funnel plot's control limits need every PCN in England to
# reflect the true national spread — filter_pcn_icb() below is the thin
# final step for ICB-only views, if one is ever needed.
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

# Practice-level GP+DPC FTE summed to PCN, alongside PCN-employed (mostly
# ARRS) FTE — the two raw ingredients of a PCN's actual staffing total,
# not yet combined (see compute_funnel.R).
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

# Population by age band and sex, at PRACTICE level — the finest
# granularity available, kept unaggregated here so it can be joined
# against a practice-level IMD quintile (practice_imd_quintile(), below)
# before summing to PCN, per CLAUDE.md's collate-at-practice-level-first
# rule. Age bands match Mukhtar et al. 2018 (Br J Gen Pract, see
# compute_funnel.R for full citation) so this codebase's own fitted
# staffing model can be checked against that paper's published rate
# ratios on a like-for-like basis.
practice_need_bands <- function(practice_registration) {
  band_lookup <- c(
    "0_4" = "under_5",
    "5_9" = "5_14", "10_14" = "5_14",
    "15_19" = "15_24", "20_24" = "15_24",
    "25_29" = "25_44", "30_34" = "25_44", "35_39" = "25_44", "40_44" = "25_44",
    "45_49" = "45_64", "50_54" = "45_64", "55_59" = "45_64", "60_64" = "45_64",
    "65_69" = "65_74", "70_74" = "65_74",
    "75_79" = "over_74", "80_84" = "over_74", "85_89" = "over_74",
    "90_94" = "over_74", "95+" = "over_74"
  )

  # SEX == "ALL" rows only ever carry the grand total (AGE_GROUP_5 ==
  # "ALL") — the age-band breakdown only exists per sex, so male and
  # female rows are kept separate here (summed together would lose the
  # sex split the staffing model needs). Verified empirically (per
  # CLAUDE.md) rather than assumed.
  practice_registration |>
    dplyr::filter(SEX %in% c("MALE", "FEMALE"), AGE_GROUP_5 != "ALL") |>
    dplyr::mutate(age_band = band_lookup[AGE_GROUP_5]) |>
    dplyr::select(PRACTICE_CODE = ORG_CODE, age_band, sex = SEX, NUMBER_OF_PATIENTS) |>
    dplyr::group_by(PRACTICE_CODE, age_band, sex) |>
    dplyr::summarise(pop = sum(NUMBER_OF_PATIENTS, na.rm = TRUE), .groups = "drop")
}

# National population-weighted IMD quintile membership per practice.
# Weighted (not simple) quantiles, because IMD scores are indexed to
# small areas of very different population sizes — weighting by each
# practice's own registered population approximates a *patient*-level
# quintile (as used by Mukhtar et al. 2018), which is what that paper's
# quintile rate ratios were actually estimated against. Quintiled at
# practice level, not PCN level, so a PCN blending one deprived and one
# affluent practice gets genuine mixed quintile shares downstream
# (pcn_need_composition()) rather than one misleading "medium" quintile
# for its whole population.
practice_imd_quintile <- function(practice_imd, practice_registration) {
  practice_list_size <- practice_registration |>
    dplyr::filter(SEX == "ALL", AGE_GROUP_5 == "ALL") |>
    dplyr::select(PRACTICE_CODE = ORG_CODE, list_size = NUMBER_OF_PATIENTS)

  practice_imd |>
    dplyr::inner_join(practice_list_size, by = "PRACTICE_CODE") |>
    dplyr::filter(!is.na(IMD_SCORE), !is.na(list_size)) |>
    dplyr::arrange(IMD_SCORE) |>
    dplyr::mutate(
      cum_pop_share = cumsum(list_size) / sum(list_size),
      imd_quintile = pmin(5, ceiling(cum_pop_share * 5))
    ) |>
    dplyr::select(PRACTICE_CODE, IMD_SCORE, imd_quintile)
}

# Base-dplyr replacement for tidyr::pivot_wider (not available in this
# renv library): sums value_col in df by PCN_CODE for each level of
# key_col in key_values, one output column per level, name-prefixed.
wide_pivot_sum <- function(df, key_col, key_values, value_col, prefix) {
  Reduce(
    function(acc, k) {
      col <- df |>
        dplyr::filter(.data[[key_col]] == k) |>
        dplyr::group_by(PCN_CODE) |>
        dplyr::summarise(value = sum(.data[[value_col]], na.rm = TRUE), .groups = "drop") |>
        dplyr::rename(!!paste0(prefix, k) := value)
      dplyr::full_join(acc, col, by = "PCN_CODE")
    },
    key_values,
    dplyr::distinct(df, PCN_CODE)
  )
}

# PCN-level population composition: each age band's share of the PCN's
# list, the female share, and IMD-quintile shares (population-weighted,
# rolled up from each practice's own quintile) — the covariates
# compute_funnel.R's staffing model regresses on.
#
# Age is coarsened here to 3 bands (under-15, 15-64, 65+) rather than the
# 7 literature-aligned bands practice_need_bands() itself outputs. A
# first version of this model used the full 7 bands to match Mukhtar et
# al. 2018's own categories exactly, but that badly overfit: with ~1,300
# PCNs and 7 correlated age-share covariates (age-band shares are
# compositional — a PCN with a high 65-74 share almost always also has a
# high 75+ share), the fit was unstable (one elderly coefficient came out
# as a 300x rate ratio with a 95% CI spanning 33x-2706x — not a real
# effect, a collinearity artefact). Coarsening back to 3 bands is exactly
# what the earlier (pre-literature-comparison) version of this model used
# successfully. compute_funnel.R's national_model_comparison() rebases
# Mukhtar's finer published rate ratios onto these same 3 coarse bands
# (population-weighted, using this pipeline's own national age
# distribution) so the comparison against literature still works, just
# at coarser resolution for age. Sex and IMD-quintile shares are
# unaffected — those weren't part of the instability.
#
# Reference categories (age 15-64, male, IMD quintile 1) are deliberately
# left out of the share columns; they're captured by the regression's
# intercept, not by a share of their own.
pcn_need_composition <- function(practice_need_bands, practice_imd_quintile, pcn_list_size, epcn_mapping) {
  practice_pcn <- pcn_icb_lookup(epcn_mapping) |> dplyr::distinct(PRACTICE_CODE, PCN_CODE)

  coarse_band_lookup <- c(
    "under_5" = "under_15", "5_14" = "under_15",
    "15_24" = "15_64", "25_44" = "15_64", "45_64" = "15_64",
    "65_74" = "65_plus", "over_74" = "65_plus"
  )

  pcn_bands <- practice_need_bands |>
    dplyr::inner_join(practice_pcn, by = "PRACTICE_CODE") |>
    dplyr::mutate(coarse_band = coarse_band_lookup[age_band]) |>
    dplyr::group_by(PCN_CODE, coarse_band, sex) |>
    dplyr::summarise(pop = sum(pop, na.rm = TRUE), .groups = "drop")

  age_bands <- c("under_15", "65_plus")
  age_wide <- wide_pivot_sum(pcn_bands, "coarse_band", age_bands, "pop", "pop_")

  female_wide <- pcn_bands |>
    dplyr::filter(sex == "FEMALE") |>
    dplyr::group_by(PCN_CODE) |>
    dplyr::summarise(pop_female = sum(pop, na.rm = TRUE), .groups = "drop")

  pcn_quintile_pop <- practice_need_bands |>
    dplyr::group_by(PRACTICE_CODE) |>
    dplyr::summarise(practice_pop = sum(pop, na.rm = TRUE), .groups = "drop") |>
    dplyr::inner_join(practice_imd_quintile, by = "PRACTICE_CODE") |>
    dplyr::inner_join(practice_pcn, by = "PRACTICE_CODE") |>
    dplyr::group_by(PCN_CODE, imd_quintile) |>
    dplyr::summarise(pop = sum(practice_pop, na.rm = TRUE), .groups = "drop")

  quintile_wide <- wide_pivot_sum(pcn_quintile_pop, "imd_quintile", 1:5, "pop", "pop_q")

  age_wide |>
    dplyr::inner_join(female_wide, by = "PCN_CODE") |>
    dplyr::inner_join(quintile_wide, by = "PCN_CODE") |>
    dplyr::mutate(dplyr::across(dplyr::starts_with("pop_"), ~ dplyr::coalesce(.x, 0))) |>
    dplyr::inner_join(
      dplyr::select(pcn_list_size, PCN_CODE, PCN_NAME, ICB_CODE, list_size), by = "PCN_CODE"
    ) |>
    dplyr::mutate(
      share_under_15 = pop_under_15 / list_size,
      share_65_plus  = pop_65_plus / list_size,
      share_female   = pop_female / list_size,
      share_q2       = pop_q2 / list_size,
      share_q3       = pop_q3 / list_size,
      share_q4       = pop_q4 / list_size,
      share_q5       = pop_q5 / list_size
    ) |>
    dplyr::select(PCN_CODE, PCN_NAME, ICB_CODE, list_size, dplyr::starts_with("share_"))
}

# Practice-level DNA (Did Not Attend) rate — sum counts, then divide;
# NEVER average per-row rates. Summing first avoids Simpson's-paradox-
# style bias once this rolls up to PCN level: a PCN blending a
# high-volume low-DNA practice with a low-volume high-DNA practice must
# reflect its true population-weighted rate, not an unweighted average
# of two practice rates. Internal diagnostic only (see
# compute_funnel.R/CLAUDE.md) — not a covariate in the staffing model,
# and never rendered into report/pcn_report.qmd.
practice_dna_rate <- function(practice_dna) {
  practice_dna |>
    dplyr::group_by(PRACTICE_CODE) |>
    dplyr::summarise(
      dna_count = sum(n[APPT_STATUS == "DNA"], na.rm = TRUE),
      attended_count = sum(n[APPT_STATUS == "Attended"], na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::mutate(dna_rate_pct = 100 * dna_count / (dna_count + attended_count))
}

# PCN-level DNA rate: sums each constituent practice's DNA and Attended
# counts to PCN level before dividing — same sum-then-divide principle
# as practice_dna_rate(), never averaging practice-level dna_rate_pct
# values.
pcn_dna_rate <- function(practice_dna_rate, epcn_mapping, primary_icb) {
  pcn_icb_lookup(epcn_mapping) |>
    dplyr::distinct(PRACTICE_CODE, PCN_CODE, PCN_NAME) |>
    dplyr::inner_join(practice_dna_rate, by = "PRACTICE_CODE") |>
    dplyr::group_by(PCN_CODE, PCN_NAME) |>
    dplyr::summarise(
      dna_count = sum(dna_count, na.rm = TRUE),
      attended_count = sum(attended_count, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::mutate(dna_rate_pct = 100 * dna_count / (dna_count + attended_count)) |>
    dplyr::inner_join(dplyr::select(primary_icb, PCN_CODE, ICB_CODE), by = "PCN_CODE")
}

# Practice-level staffing snapshot: list size + practice/DPC FTE (EXCLUDES
# ARRS — genuinely PCN-native, no practice-level equivalent, see
# pcn_workforce()). Needed for practice_pcn_drilldown() below. Parallel
# in style to practice_need_bands()/practice_imd_quintile() — a plain
# national-scale practice-level table, not yet PCN-filtered.
practice_staffing_snapshot <- function(practice_registration, practice_gp_workforce) {
  practice_list_size <- practice_registration |>
    dplyr::filter(SEX == "ALL", AGE_GROUP_5 == "ALL") |>
    dplyr::select(PRACTICE_CODE = ORG_CODE, list_size = NUMBER_OF_PATIENTS)

  practice_list_size |>
    dplyr::left_join(practice_gp_workforce, by = "PRACTICE_CODE") |>
    dplyr::mutate(
      practice_fte = dplyr::coalesce(practice_fte, 0),
      practice_fte_per_1k_patients = 1000 * practice_fte / list_size
    )
}

# Practice-level drill-down for one PCN: each constituent practice's
# staffing intensity and DNA rate, compared to the REST of its PCN
# (excluding itself) — not the whole-PCN average. Internal diagnostic
# only (see CLAUDE.md) — for investigating a flagged outlier PCN, or in
# a follow-up call, never rendered into report/pcn_report.qmd. Not a
# registered target — parameterised per-PCN, exactly like
# report/pcn_report.qmd's own params$pcn_code filtering of pre-built
# national targets.
#
# ARRS exception: practice_fte_per_1k_patients here is practice/DPC FTE
# ONLY — ARRS FTE has no practice-level equivalent (genuinely PCN-native,
# see pcn_workforce()), so this breakdown can only decompose the
# practice/DPC portion of a PCN's actual_fte. Stated explicitly here and
# in the output column names, rather than silently omitting ARRS or
# fabricating a practice-level split no source publishes.
practice_pcn_drilldown <- function(pcn_code, epcn_mapping,
                                    practice_staffing_snapshot, practice_dna_rate) {
  practices <- pcn_icb_lookup(epcn_mapping) |>
    dplyr::filter(PCN_CODE == pcn_code) |>
    dplyr::distinct(PRACTICE_CODE, PCN_CODE, PCN_NAME)

  if (nrow(practices) == 0) stop("pcn_code not found in epcn_mapping: ", pcn_code)

  detail <- practices |>
    dplyr::left_join(practice_staffing_snapshot, by = "PRACTICE_CODE") |>
    dplyr::left_join(practice_dna_rate, by = "PRACTICE_CODE")

  pcn_list_size_total <- sum(detail$list_size, na.rm = TRUE)
  pcn_practice_fte_total <- sum(detail$practice_fte, na.rm = TRUE)
  pcn_dna_count_total <- sum(detail$dna_count, na.rm = TRUE)
  pcn_attended_count_total <- sum(detail$attended_count, na.rm = TRUE)

  detail |>
    dplyr::mutate(
      rest_list_size = pcn_list_size_total - list_size,
      rest_practice_fte = pcn_practice_fte_total - practice_fte,
      rest_practice_fte_per_1k_patients = 1000 * rest_practice_fte / rest_list_size,
      staffing_intensity_gap_pct = 100 * (practice_fte_per_1k_patients -
        rest_practice_fte_per_1k_patients) / rest_practice_fte_per_1k_patients,
      rest_dna_count = pcn_dna_count_total - dna_count,
      rest_attended_count = pcn_attended_count_total - attended_count,
      rest_dna_rate_pct = 100 * rest_dna_count / (rest_dna_count + rest_attended_count),
      dna_rate_gap_pct_points = dna_rate_pct - rest_dna_rate_pct
    )
}
