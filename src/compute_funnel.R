# Builds the per-PCN table the staffing model and funnel plot both need:
# population-composition shares (aggregate_pcn.R::pcn_need_composition())
# joined against actual FTE (practice + ARRS). A handful of PCNs have no
# rows at all in the PCN Workforce file — ambiguous between "genuinely
# zero ARRS staff" and "not captured this snapshot". Treated as zero (the
# conservative read: lower ARRS FTE only makes a PCN look more
# understaffed, so this can't be quietly assumed) but flagged so it's
# visible downstream rather than silently folded in.
pcn_staffing_data <- function(pcn_composition, pcn_workforce) {
  pcn_composition |>
    dplyr::inner_join(
      dplyr::select(pcn_workforce, PCN_CODE, practice_fte, arrs_fte),
      by = "PCN_CODE"
    ) |>
    dplyr::mutate(
      arrs_fte_missing = is.na(arrs_fte),
      arrs_fte = dplyr::coalesce(arrs_fte, 0),
      actual_fte = practice_fte + arrs_fte
    )
}

# Fits the staffing need model: actual FTE as a Poisson rate regressed on
# each PCN's own population composition (age-band shares, female share,
# IMD-quintile shares — see aggregate_pcn.R::pcn_need_composition()),
# with list_size as the exposure offset. This is the textbook approach
# FunnelPlotR's own documentation uses (fit glm(family = "poisson"), feed
# the fitted values in as the funnel plot's `denominator`) — fitted
# directly from this pipeline's own national data, nothing imported.
# quasipoisson (not poisson) so standard errors reflect the real
# overdispersion in aggregated PCN-level data rather than understating
# it; point estimates are identical to plain poisson either way.
#
# Age enters as 3 coarse bands (under-15, 15-64, 65+), not the 7
# literature-aligned bands pcn_need_composition() could in principle
# support — see aggregate_pcn.R for why: the 7-band version was badly
# collinear at ~1,300 PCN observations (one elderly coefficient came out
# as a 300x rate ratio with a 95% CI spanning 33x-2706x — a fitting
# artefact, not a real effect). Reference categories (omitted from the
# formula, captured by the intercept): age 15-64, male, IMD quintile 1.
fit_staffing_model <- function(national_pcn_composition, national_pcn_workforce) {
  staffing <- pcn_staffing_data(national_pcn_composition, national_pcn_workforce)

  stats::glm(
    actual_fte ~ share_under_15 + share_65_plus + share_female +
      share_q2 + share_q3 + share_q4 + share_q5,
    family = stats::quasipoisson(link = "log"),
    offset = log(list_size),
    data = staffing
  )
}

# Funnel-plot outlier flagging on staffing — Spiegelhalter method via
# FunnelPlotR, applied so a PCN is identified because its staffing is a
# statistical outlier against its own patient need, not just because it
# happens to rank highest in some list. "Expected" FTE is this PCN's
# fitted value from fit_staffing_model() above — guaranteed positive by
# the Poisson log link, unlike the old lm()-based approach, which needed
# a manual check.
#
# This still treats FTE as if it behaves like a count for Poisson-style
# control limits to be meaningful, which it isn't exactly (it's
# fractional, not a count of discrete events) — the same approximation
# classic SMR-style workforce funnel plots make; stated here as an
# assumption, not fact, per CLAUDE.md.
#
# Run at national scale, not just one ICB, so both the model and the
# funnel's control limits reflect the true national spread.
national_staffing_funnel <- function(national_staffing_model, national_pcn_composition, national_pcn_workforce) {
  staffing <- pcn_staffing_data(national_pcn_composition, national_pcn_workforce)

  fp_data <- dplyr::mutate(
    staffing,
    expected_fte = stats::predict(national_staffing_model, newdata = staffing, type = "response")
  )
  stopifnot(all(fp_data$expected_fte > 0))

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
      dplyr::distinct(national_pcn_composition, PCN_CODE, PCN_NAME, ICB_CODE),
      by = "PCN_CODE"
    ) |>
    dplyr::arrange(staffing_ratio_pct)
}

# Published rate ratios from:
#   Mukhtar TK, Bankhead C, Stevens S, Perera R, Holt TA, Salisbury C,
#   Hobbs FDR. "Factors associated with consultation rates in general
#   practice in England, 2013-2014: a cross-sectional study." Br J Gen
#   Pract. 2018;68(670):e370-e377. DOI: 10.3399/bjgp18X695981. (CC BY-NC 4.0)
#   Table 3, "All consultations", multivariate multilevel negative-binomial
#   model, CPRD data, 304,937 patients, 316 English practices.
#
# Used ONLY as an external corroboration check (national_model_comparison(),
# below) against our own fitted model -- NOT as production weights. Our
# production "expected FTE" is entirely self-fitted from this pipeline's
# own national data (fit_staffing_model()); none of this ever feeds into
# national_staffing_funnel().
#
# Age rate ratios at Mukhtar's own fine-grained bands, reference = 5-14.
# Kept at this fine grain (not our own coarser 3 bands) so they can be
# correctly population-weighted and re-based by
# mukhtar_implied_coarse_age_rr() below, rather than averaged naively.
mukhtar_2018_fine_age_rr <- tibble::tribble(
  ~age_band,  ~rr_published,
  "under_5",  1.88,
  "5_14",     1.00,
  "15_24",    1.65,
  "25_44",    1.88,
  "45_64",    2.22,
  "65_74",    2.89,
  "over_74",  3.97
)

mukhtar_2018_other_rr <- tibble::tribble(
  ~term,          ~rr_published,
  "share_female", 1.21,
  "share_q2",     1.03,
  "share_q3",     1.06,
  "share_q4",     1.11,
  "share_q5",     1.18
)

# Blends Mukhtar's fine age-band rate ratios into our own coarser 3 bands
# (under-15/15-64/65+ -- see aggregate_pcn.R::pcn_need_composition() for
# why age was coarsened), weighted by each fine band's own share of the
# *national* population (this pipeline's own data, not assumed), then
# re-bases the blend onto our own reference band (15-64) since Mukhtar's
# own reference is 5-14, a different band than ours -- without this
# re-basing step the two sets of numbers wouldn't be comparable at all.
mukhtar_implied_coarse_age_rr <- function(national_practice_need_bands) {
  coarse_band_lookup <- c(
    "under_5" = "under_15", "5_14" = "under_15",
    "15_24" = "15_64", "25_44" = "15_64", "45_64" = "15_64",
    "65_74" = "65_plus", "over_74" = "65_plus"
  )

  blended <- national_practice_need_bands |>
    dplyr::group_by(age_band) |>
    dplyr::summarise(pop = sum(pop, na.rm = TRUE), .groups = "drop") |>
    dplyr::mutate(coarse_band = coarse_band_lookup[age_band]) |>
    dplyr::inner_join(mukhtar_2018_fine_age_rr, by = "age_band") |>
    dplyr::group_by(coarse_band) |>
    dplyr::summarise(rr_mukhtar_implied = stats::weighted.mean(rr_published, pop), .groups = "drop")

  reference_rr <- blended$rr_mukhtar_implied[blended$coarse_band == "15_64"]

  blended |>
    dplyr::filter(coarse_band != "15_64") |>
    dplyr::mutate(
      term = paste0("share_", coarse_band),
      rr_published = rr_mukhtar_implied / reference_rr
    ) |>
    dplyr::select(term, rr_published)
}

# Side-by-side comparison of our own fitted rate ratios (with 95% CIs,
# from the quasipoisson fit) against Mukhtar et al. 2018's published
# ones (age terms re-based to our coarser bands, see
# mukhtar_implied_coarse_age_rr() above). Internal diagnostic only --
# not read by the report.
#
# Our coefficients are estimated on PCN-level population *composition
# shares* (an ecological/aggregate regression: what population mix
# predicts total PCN staffing), not on individual patients like
# Mukhtar's (what predicts one patient's own consultation rate) -- the
# two aren't mathematically identical even in the best case, so a
# corroborating match is reassuring, not proof, and a mismatch isn't
# necessarily wrong, just worth understanding before trusting either
# figure too far. Stated here as an assumption, not fact, per CLAUDE.md.
national_model_comparison <- function(national_staffing_model, national_practice_need_bands) {
  est <- coef(national_staffing_model)
  ci <- suppressMessages(confint(national_staffing_model))

  ours <- tibble::tibble(
    term = names(est),
    rr_fitted = exp(unname(est)),
    rr_fitted_lower = exp(ci[names(est), 1]),
    rr_fitted_upper = exp(ci[names(est), 2])
  ) |>
    dplyr::filter(term != "(Intercept)")

  published <- dplyr::bind_rows(
    mukhtar_implied_coarse_age_rr(national_practice_need_bands),
    mukhtar_2018_other_rr
  )

  dplyr::inner_join(ours, published, by = "term") |>
    dplyr::mutate(
      dplyr::across(dplyr::starts_with("rr_"), ~ round(.x, 2)),
      diff_from_published = round(rr_fitted - rr_published, 2)
    ) |>
    dplyr::arrange(term)
}
