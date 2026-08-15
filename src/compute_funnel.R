# Pools each PCN's raw staffing inputs (see ref/CONCEPT.md) — patient
# need (list size weighted by deprivation) against current staff FTE
# already in post. Takes already PCN-aggregated inputs (aggregate_pcn.R)
# — no further ICB filtering needed here. No score is computed here;
# these raw figures feed straight into the funnel-plot check below.

pcn_staffing_need <- function(pcn_list_size, pcn_imd, pcn_workforce) {
  pcn_list_size |>
    dplyr::select(PCN_CODE, PCN_NAME, list_size) |>
    dplyr::inner_join(dplyr::select(pcn_imd, PCN_CODE, imd_score), by = "PCN_CODE") |>
    dplyr::inner_join(
      dplyr::select(pcn_workforce, PCN_CODE, practice_fte, arrs_fte),
      by = "PCN_CODE"
    ) |>
    dplyr::mutate(
      # A handful of PCNs have no rows at all in the PCN Workforce file —
      # ambiguous between "genuinely zero ARRS staff" and "not captured
      # this snapshot". Treated as zero (the conservative read: lower
      # ARRS FTE only makes a PCN look more understaffed, so this can't
      # be quietly assumed) but flagged so it's visible downstream rather
      # than silently folded in.
      arrs_fte_missing = is.na(arrs_fte),
      arrs_fte = dplyr::coalesce(arrs_fte, 0)
    )
}

# Funnel-plot outlier flagging on staffing — Spiegelhalter method via
# FunnelPlotR, applied so a PCN is identified because its staffing is a
# statistical outlier against its own patient need, not just because it
# happens to rank highest in some list.
#
# "Expected" FTE is built by indirect standardisation: the national
# average FTE per unit of weighted need (list_size * imd_score), applied
# to each PCN's own weighted need. This assumes FTE behaves enough like
# a count for Poisson-based control limits to be meaningful, which it
# isn't exactly (it's fractional, not a count of discrete events) — the
# same approximation classic SMR-style workforce funnel plots make;
# stated here as an assumption, not fact, per CLAUDE.md.
#
# Run at national scale, not just one ICB, so control limits reflect the
# true national spread of staffing intensity.
national_staffing_funnel <- function(national_pcn_list_size, national_pcn_imd, national_pcn_workforce) {
  staffing <- pcn_staffing_need(national_pcn_list_size, national_pcn_imd, national_pcn_workforce) |>
    dplyr::mutate(
      actual_fte = practice_fte + arrs_fte,
      weighted_need = list_size * imd_score
    )

  national_fte_per_weighted_need <- sum(staffing$actual_fte) / sum(staffing$weighted_need)

  fp_data <- dplyr::mutate(staffing, expected_fte = national_fte_per_weighted_need * weighted_need)

  fp <- FunnelPlotR::funnel_plot(
    .data = fp_data,
    numerator = actual_fte,
    denominator = expected_fte,
    group = PCN_CODE,
    data_type = "SR",
    limit = 95,
    draw_adjusted = TRUE
  )

  fp$aggregated_data |>
    dplyr::rename(PCN_CODE = group, staffing_ratio = rr) |>
    dplyr::mutate(
      staffing_ratio_pct = 100 * staffing_ratio,
      dplyr::across(c(OD95LCL, OD95UCL, OD99LCL, OD99UCL), ~ 100 * .x),
      funnel_flag = dplyr::case_when(
        staffing_ratio_pct < OD99LCL | staffing_ratio_pct > OD99UCL ~ "outside_99.8pct",
        staffing_ratio_pct < OD95LCL | staffing_ratio_pct > OD95UCL ~ "outside_95pct",
        TRUE ~ "within_expected_range"
      ),
      direction = dplyr::case_when(
        funnel_flag == "within_expected_range" ~ NA_character_,
        staffing_ratio_pct < OD95LCL ~ "understaffed_vs_expected",
        TRUE ~ "overstaffed_vs_expected"
      )
    ) |>
    dplyr::select(
      PCN_CODE, expected_fte = denominator, actual_fte = numerator, staffing_ratio_pct,
      od95_lower_pct = OD95LCL, od95_upper_pct = OD95UCL,
      od99_8_lower_pct = OD99LCL, od99_8_upper_pct = OD99UCL,
      funnel_flag, direction
    ) |>
    dplyr::mutate(
      dplyr::across(dplyr::ends_with("_pct"), ~ round(.x, 1)),
      dplyr::across(c(expected_fte, actual_fte), ~ round(.x, 1))
    ) |>
    dplyr::inner_join(
      dplyr::distinct(national_pcn_list_size, PCN_CODE, PCN_NAME, ICB_CODE),
      by = "PCN_CODE"
    ) |>
    dplyr::arrange(staffing_ratio_pct)
}
