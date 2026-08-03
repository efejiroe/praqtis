# Phase 0 reconnaissance: is ACSC admissions data obtainable at PCN level?
# Standalone exploration script (not yet part of the {targets} pipeline —
# Phase 1 introduces _targets.R). Findings written up in PHASE0_FINDINGS.md.

find_acsc_indicators <- function(terms = c(
  "ambulatory care sensitive", "ACSC", "avoidable admission",
  "emergency admission", "unplanned admission", "unplanned hospitalisation"
)) {
  ind <- fingertipsR::indicators_unique()
  pattern <- paste(terms, collapse = "|")
  ind[grepl(pattern, ind$IndicatorName, ignore.case = TRUE), ]
}

indicator_area_types <- function(indicator_id) {
  at <- fingertipsR::area_types()
  iat <- fingertipsR::indicator_areatypes()
  these <- iat[iat$IndicatorID == indicator_id, ]
  unique(merge(these, at, by = "AreaTypeID")[, c("AreaTypeID", "AreaTypeName")])
}

pcn_related_profiles <- function() {
  pr <- fingertipsR::profiles()
  pr[grepl("PCN|Primary Care", pr$ProfileName, ignore.case = TRUE), ]
}
