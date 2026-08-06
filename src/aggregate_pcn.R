# Aggregate registered-patient list size to PCN level for one ICB, using
# the ePCN mapping to attach ICB identity to each PCN.

pcn_list_size_for_icb <- function(pcn_registration, epcn_mapping, icb_name) {
  # PCN_CODE "U" / PCN_NAME "Unallocated" is a placeholder spanning every
  # ICB (practices not yet assigned to a real PCN) — not a genuine PCN.
  pcn_icb <- epcn_mapping |>
    dplyr::filter(!is.na(PCN_CODE), PCN_NAME != "Unallocated") |>
    dplyr::distinct(PCN_CODE, PCN_NAME, ICB_CODE, ICB_NAME)

  pcn_registration |>
    dplyr::filter(SEX == "ALL", AGE_GROUP_5 == "ALL") |>
    dplyr::select(PCN_CODE = ORG_CODE, list_size = NUMBER_OF_PATIENTS) |>
    dplyr::inner_join(pcn_icb, by = "PCN_CODE") |>
    dplyr::filter(ICB_NAME == icb_name) |>
    dplyr::arrange(dplyr::desc(list_size))
}
