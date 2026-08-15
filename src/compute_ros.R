# ROS — Recruitment Opportunity Score (see ref/CONCEPT.md). Plain-English
# version (CLAUDE.md's explainability bar): where patient need, weighted
# by deprivation, is outgrowing current staff — the strongest case for
# the next ARRS hire. Takes already PCN-aggregated inputs
# (aggregate_pcn.R) — no further ICB filtering needed here.
#
# ros = (list_size * imd_score) / (practice_fte + arrs_fte)

pcn_ros <- function(pcn_list_size, pcn_imd, pcn_workforce) {
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
      # this snapshot". Treated as zero (the conservative read for a
      # denominator: lower ARRS FTE means a *higher*, more attention-
      # grabbing ROS, so this can't be quietly assumed) but flagged so
      # it's visible downstream rather than silently folded in.
      arrs_fte_missing = is.na(arrs_fte),
      arrs_fte = dplyr::coalesce(arrs_fte, 0),
      ros = (list_size * imd_score) / (practice_fte + arrs_fte)
    ) |>
    dplyr::arrange(dplyr::desc(ros))
}

# Funnel-plot outlier flagging on ROS's own staffing ratio — Spiegelhalter
# method via FunnelPlotR, applied so a PCN is identified because its
# staffing is a statistical outlier against its own patient need, not
# just because it happens to rank highest in the pilot.
#
# "Expected" FTE is built by indirect standardisation: the national
# average FTE per unit of weighted need, applied to each PCN's own
# weighted need (list_size * imd_score — ROS's own numerator, no new
# "need" definition introduced here). This assumes FTE behaves enough
# like a count for Poisson-based control limits to be meaningful, which
# it isn't exactly (it's fractional, not a count of discrete events) —
# the same approximation classic SMR-style workforce funnel plots make;
# stated here as an assumption, not fact, per CLAUDE.md.
#
# Run at national scale, not just the pilot ICB, for the same reason as
# PPD's peer group: control limits have to reflect the
# true national spread of staffing intensity.
national_pcn_ros_funnel <- function(national_pcn_list_size, national_pcn_imd, national_pcn_workforce) {
  ros <- pcn_ros(national_pcn_list_size, national_pcn_imd, national_pcn_workforce) |>
    dplyr::mutate(
      actual_fte = practice_fte + arrs_fte,
      weighted_need = list_size * imd_score
    )

  national_fte_per_weighted_need <- sum(ros$actual_fte) / sum(ros$weighted_need)

  fp_data <- dplyr::mutate(ros, expected_fte = national_fte_per_weighted_need * weighted_need)

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
