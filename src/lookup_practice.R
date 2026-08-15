# Practice-level lookup and PCN-context comparison — formalises the
# ad-hoc query used to check a specific practice's numbers (e.g. Nexus
# Health Group) against its own PCN. Powers the practice drill-down that
# the "Offer" stage of the funnel needs (see ref/CONCEPT.md) once a PPD
# gap points at a PCN worth looking inside. Reusable from the Quarto
# report or interactively via targets::tar_read().

practice_snapshot <- function(practice_code, practice_registration, practice_imd,
                               practice_gp_workforce, qof_practice_achievement,
                               practice_iif_indicators, epcn_mapping) {
  identity <- epcn_mapping |>
    dplyr::filter(PRACTICE_CODE == practice_code) |>
    dplyr::distinct(PRACTICE_CODE, PRACTICE_NAME, PCN_CODE, PCN_NAME, ICB_CODE, ICB_NAME)

  if (nrow(identity) != 1) {
    stop("practice_code not found (or not unique) in epcn_mapping: ", practice_code)
  }

  pull_or_na <- function(df, col) {
    v <- dplyr::pull(df, {{ col }})
    if (length(v) == 0) NA_real_ else v[1]
  }

  list_size <- pull_or_na(
    dplyr::filter(practice_registration, ORG_CODE == practice_code, SEX == "ALL", AGE_GROUP_5 == "ALL"),
    NUMBER_OF_PATIENTS
  )
  imd_score <- pull_or_na(dplyr::filter(practice_imd, PRACTICE_CODE == practice_code), IMD_SCORE)
  practice_fte <- pull_or_na(dplyr::filter(practice_gp_workforce, PRACTICE_CODE == practice_code), practice_fte)
  qof_achievement_pct <- pull_or_na(
    dplyr::filter(qof_practice_achievement, PRACTICE_CODE == practice_code),
    qof_achievement_pct_2425
  )

  acc08 <- dplyr::filter(practice_iif_indicators, PRACTICE_CODE == practice_code, IND_CODE == "NCD026")
  acc08_num <- pull_or_na(dplyr::filter(acc08, MEASURE == "ACC-08 Numerator"), VALUE)
  acc08_den <- pull_or_na(dplyr::filter(acc08, MEASURE == "ACC-08 Denominator"), VALUE)
  acc08_performance_pct <- if (is.na(acc08_den) || acc08_den == 0) NA_real_ else 100 * acc08_num / acc08_den

  tibble::tibble(
    PRACTICE_CODE = practice_code,
    PRACTICE_NAME = identity$PRACTICE_NAME,
    PCN_CODE = identity$PCN_CODE,
    PCN_NAME = identity$PCN_NAME,
    ICB_CODE = identity$ICB_CODE,
    list_size = list_size,
    imd_score = imd_score,
    practice_fte = practice_fte,
    qof_achievement_pct = qof_achievement_pct,
    acc08_performance_pct = acc08_performance_pct
  )
}

# Attaches the practice's own PCN's QOF/ACC-08 figures, the gap between
# them, and — critically — whether the practice is simply better-staffed
# than the rest of its network. A performance gap with a matching
# staffing gap is a resourcing story ("they have more people"); a
# performance gap with near-identical staffing intensity is a process
# story (the same resources doing something differently) — the second
# is the zero-extra-capacity finding worth leading a report with, and
# the first isn't, so this has to be checked before either framing is
# used, not assumed.
practice_vs_pcn <- function(snapshot, pcn_qof, pcn_tpg, pcn_workforce, pcn_list_size) {
  pcn_code <- snapshot$PCN_CODE
  pcn_qof_pct <- dplyr::filter(pcn_qof, PCN_CODE == pcn_code)$qof_achievement_pct
  pcn_acc08_pct <- dplyr::filter(pcn_tpg, PCN_CODE == pcn_code)$performance_pct
  pcn_fte <- dplyr::filter(pcn_workforce, PCN_CODE == pcn_code)$practice_fte
  pcn_list <- dplyr::filter(pcn_list_size, PCN_CODE == pcn_code)$list_size

  rest_of_pcn_fte <- pcn_fte - snapshot$practice_fte
  rest_of_pcn_list_size <- pcn_list - snapshot$list_size

  snapshot |>
    dplyr::mutate(
      pcn_qof_achievement_pct = pcn_qof_pct,
      pcn_acc08_performance_pct = pcn_acc08_pct,
      qof_gap_vs_pcn = qof_achievement_pct - pcn_qof_pct,
      acc08_gap_vs_pcn = acc08_performance_pct - pcn_acc08_pct,
      practice_fte_per_1k_patients = 1000 * practice_fte / list_size,
      rest_of_pcn_fte_per_1k_patients = 1000 * rest_of_pcn_fte / rest_of_pcn_list_size,
      staffing_intensity_gap_pct = 100 * (practice_fte_per_1k_patients - rest_of_pcn_fte_per_1k_patients) /
        rest_of_pcn_fte_per_1k_patients
    )
}
