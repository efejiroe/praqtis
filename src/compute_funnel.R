# Funnel-plot outlier flagging on TPG's ACC-08 performance, Spiegelhalter
# method via FunnelPlotR — see CLAUDE.md's constraint to aggregate to PCN
# before flagging, and the plain-English test worked through in
# conversation: control limits widen automatically for smaller PCNs, so
# a PCN isn't flagged just because it's small and its rate is noisy.
#
# Run at national scale, not just the pilot ICB — the funnel's control
# limits have to reflect the true national spread of PCN performance, the
# same reason PPD's peer group had to go national. Overdispersion-
# adjusted limits (draw_adjusted, the package's default recommendation)
# are used rather than raw Poisson/binomial limits, since real PCNs
# genuinely vary in performance beyond what sampling noise alone would
# produce — treating that as pure noise would systematically under-flag.
#
# Two tiers, matching standard funnel-plot practice: 95% ("worth a
# look") and 99.8% ("clear outlier"). FunnelPlotR's `limit` argument only
# drives which tier populates its own `outlier` column, but both tiers'
# control limits are always present in the output, so one call is enough
# to build both tiers ourselves.

national_pcn_tpg_funnel <- function(national_pcn_iif) {
  tpg <- pcn_tpg(national_pcn_iif)

  fp <- FunnelPlotR::funnel_plot(
    .data = tpg,
    numerator = numerator,
    denominator = denominator,
    group = PCN_CODE,
    data_type = "PR",
    limit = 95,
    draw_adjusted = TRUE
  )

  fp$aggregated_data |>
    dplyr::rename(PCN_CODE = group, performance_pct = rr) |>
    dplyr::mutate(
      performance_pct = 100 * performance_pct,
      dplyr::across(c(OD95LCL, OD95UCL, OD99LCL, OD99UCL), ~ 100 * .x),
      funnel_flag = dplyr::case_when(
        performance_pct < OD99LCL | performance_pct > OD99UCL ~ "outside_99.8pct",
        performance_pct < OD95LCL | performance_pct > OD95UCL ~ "outside_95pct",
        TRUE ~ "within_expected_range"
      ),
      direction = dplyr::case_when(
        funnel_flag == "within_expected_range" ~ NA_character_,
        performance_pct < OD95LCL ~ "below_expected",
        TRUE ~ "above_expected"
      )
    ) |>
    dplyr::select(
      PCN_CODE, denominator, numerator, performance_pct,
      od95_lower_pct = OD95LCL, od95_upper_pct = OD95UCL,
      od99_8_lower_pct = OD99LCL, od99_8_upper_pct = OD99UCL,
      funnel_flag, direction
    ) |>
    dplyr::mutate(dplyr::across(dplyr::ends_with("_pct"), ~ round(.x, 1))) |>
    dplyr::inner_join(
      dplyr::distinct(tpg, PCN_CODE, PCN_NAME, ICB_CODE),
      by = "PCN_CODE"
    ) |>
    dplyr::arrange(performance_pct)
}
