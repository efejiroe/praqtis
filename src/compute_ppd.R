# PPD — Peer Performance Deficit (see ref/CONCEPT.md). Plain-English
# version (CLAUDE.md's bar): how a PCN compares to others that actually
# look like it — similar size, deprivation, and disease burden — not the
# national average, which flattens very different PCNs into one number.
#
# No ready-made "similar PCN" comparator is public (see ref/CONCEPT.md),
# so this replicates NHS England's own published method for the old
# "Similar 10 CCG" tool: Euclidean distance on standardised variables.
# One documented simplification: NHS England's method weighted its
# variables (size, demographics, deprivation, ethnicity); the exact
# weights aren't published, so this uses equal weighting across list
# size, IMD, and QOF disease-register prevalence after standardising —
# stated here as an assumption, not fact, per CLAUDE.md.

zscore <- function(x) (x - mean(x, na.rm = TRUE)) / stats::sd(x, na.rm = TRUE)

national_pcn_features <- function(national_pcn_list_size, national_pcn_imd, national_pcn_prevalence) {
  national_pcn_list_size |>
    dplyr::select(PCN_CODE, PCN_NAME, ICB_CODE, list_size) |>
    dplyr::inner_join(
      dplyr::select(national_pcn_imd, PCN_CODE, imd_score), by = "PCN_CODE"
    ) |>
    dplyr::inner_join(
      dplyr::select(national_pcn_prevalence, PCN_CODE, prevalence_index), by = "PCN_CODE"
    )
}

find_like_pcns <- function(national_pcn_features, target_pcn_code, k = 10) {
  vars <- c("list_size", "imd_score", "prevalence_index")

  complete <- national_pcn_features |>
    dplyr::filter(dplyr::if_all(dplyr::all_of(vars), ~ !is.na(.x)))

  scaled <- complete |>
    dplyr::mutate(dplyr::across(dplyr::all_of(vars), zscore))

  target_row <- dplyr::filter(scaled, PCN_CODE == target_pcn_code)
  if (nrow(target_row) != 1) {
    stop("target_pcn_code not found (or not unique) in national_pcn_features")
  }

  scaled |>
    dplyr::filter(PCN_CODE != target_pcn_code) |>
    dplyr::mutate(
      distance = sqrt(
        (list_size - target_row$list_size)^2 +
          (imd_score - target_row$imd_score)^2 +
          (prevalence_index - target_row$prevalence_index)^2
      )
    ) |>
    dplyr::arrange(distance) |>
    dplyr::slice_head(n = k) |>
    dplyr::select(PCN_CODE, PCN_NAME, ICB_CODE, distance)
}

pcn_ppd <- function(national_pcn_features, national_pcn_qof, target_pcn_code, k = 10) {
  peers <- find_like_pcns(national_pcn_features, target_pcn_code, k = k)

  peer_qof <- national_pcn_qof |>
    dplyr::filter(PCN_CODE %in% peers$PCN_CODE) |>
    dplyr::pull(qof_achievement_pct)

  own_qof <- national_pcn_qof |>
    dplyr::filter(PCN_CODE == target_pcn_code) |>
    dplyr::pull(qof_achievement_pct)

  tibble::tibble(
    PCN_CODE = target_pcn_code,
    peer_median_qof_achievement_pct = stats::median(peer_qof, na.rm = TRUE),
    own_qof_achievement_pct = own_qof,
    ppd = stats::median(peer_qof, na.rm = TRUE) - own_qof,
    n_peers_with_qof = sum(!is.na(peer_qof)),
    n_peers = length(peer_qof)
  )
}

pcn_ppd_for_pcns <- function(national_pcn_features, national_pcn_qof, pcn_codes, k = 10) {
  dplyr::bind_rows(lapply(pcn_codes, function(code) {
    pcn_ppd(national_pcn_features, national_pcn_qof, code, k = k)
  }))
}
