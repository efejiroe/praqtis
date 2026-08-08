# TPG — Threshold Proximity Gap (see ref/CONCEPT.md). Plain-English
# version (CLAUDE.md's bar): how close a PCN is to the funding threshold
# it's currently missing.
#
# Leading with IIF only for now (not QOF), per direction — IIF is the
# scheme that actually carries an explicit "target threshold" tied to a
# specific £ payment; QOF is points-accumulation without the same
# threshold/tier structure. QOF-based TPG can be added later.
#
# Thresholds transcribed by hand from NHS England's 2023/24 IIF guidance
# (PRN00157, page 18 — https://www.england.nhs.uk/wp-content/uploads/2023/03/PRN00157-ncdes-investment-and-impact-fund-2023-24-guidance.pdf).
# Not a data file, so this can't be fetched programmatically — someone
# has to read the PDF.
#
# Of the 4 indicator codes in our IIF data (fetch_iif.R), only ACC-08
# (NCD026) is confirmed as one of the five official 2023/24 IIF
# indicators with a published threshold in that guidance (the others are
# VI-02, VI-03, HI-03, CAN-02 — none of which appear in our data at all).
# ACC-10, ACC-10b, and EHCH-04 do appear in the same NHS Digital MI
# release, but are NOT part of the 5-indicator 2023/24 IIF scheme per the
# guidance — most likely Capacity and Access Payment indicators tracked
# in the same file, or carried over from an earlier scheme year. Their
# thresholds live in a different guidance document we haven't identified
# and gone looking for, so they're excluded here rather than guessed at.
# "This can always be expanded" — add a row to iif_thresholds and a
# lookup once that document is found.

iif_thresholds <- tibble::tribble(
  ~IND_CODE, ~indicator_name, ~numerator_measure,   ~denominator_measure,   ~lower_threshold_pct, ~upper_threshold_pct, ~points,
  "NCD026",  "ACC-08",        "ACC-08 Numerator",   "ACC-08 Denominator",  85,                    90,                   71
)

pcn_tpg <- function(national_pcn_iif) {
  led <- iif_thresholds[1, ]

  numerator <- national_pcn_iif |>
    dplyr::filter(IND_CODE == led$IND_CODE, MEASURE == led$numerator_measure) |>
    dplyr::select(PCN_CODE, PCN_NAME, ICB_CODE, numerator = VALUE)

  denominator <- national_pcn_iif |>
    dplyr::filter(IND_CODE == led$IND_CODE, MEASURE == led$denominator_measure) |>
    dplyr::select(PCN_CODE, denominator = VALUE)

  numerator |>
    dplyr::inner_join(denominator, by = "PCN_CODE") |>
    dplyr::mutate(
      indicator = led$indicator_name,
      performance_pct = 100 * numerator / denominator,
      # Positive tpg = short of the upper threshold (missing some/all
      # points); zero or negative = already earning full points.
      tpg = led$upper_threshold_pct - performance_pct,
      achievement_points_pct = dplyr::case_when(
        performance_pct >= led$upper_threshold_pct ~ 100,
        performance_pct <= led$lower_threshold_pct ~ 0,
        TRUE ~ 100 * (performance_pct - led$lower_threshold_pct) /
          (led$upper_threshold_pct - led$lower_threshold_pct)
      )
    ) |>
    dplyr::arrange(dplyr::desc(tpg))
}
