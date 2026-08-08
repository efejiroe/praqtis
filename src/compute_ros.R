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
