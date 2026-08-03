# Phase 0 — Reconnaissance findings

**Question**: is ACSC (ambulatory care sensitive conditions) emergency admissions data obtainable at PCN level via public sources?

**Answer: no.** Not at PCN level, and not at ICB or sub-ICB (former CCG) level either, for the canonical ACSC measure. This changes what Phase 1–5 can be built on.

## What was checked

Using `fingertipsR` (OHID's public Fingertips API — the primary public source for this kind of small-area health data):

1. Searched all 1,511 indicators in the catalogue for "ambulatory care sensitive" / "ACSC" → one direct match:
   - **IndicatorID 2521** — *"Unplanned hospitalisation for chronic ambulatory care sensitive [conditions]"*
   - Available area types: **Counties & UAs (2019/20 vintage) and England only.** Not ICBs, not sub-ICB, not PCN.
2. Broadened the search to adjacent/component indicators (avoidable admissions, unplanned hospitalisation, emergency admissions for specific ACSC-type conditions):
   - Three other "vintage 2019/20" indicators (2503, 2504, 2520 — acute conditions not usually requiring hospital, children's LRTI, asthma/diabetes/epilepsy under-19s) are **all capped at County/UA (2019/20) + England**, same as 2521. These read as a discontinued/archived indicator set — likely the old CCG Outcomes Indicator Set (CCG OIS), which was retired after CCGs became ICBs in 2022 (its NHS England publication page now 404s).
   - More recent, still-updated indicators exist for **individual conditions** that overlap with ACSC (zero/one-day admissions for pneumonia and bronchiolitis, dementia emergency admissions, child gastroenteritis/LRTI admissions) — these reach down to **ICB (221) and ICB sub-locations/former-CCG (66)** level, but not PCN, and none of them is "ACSC" as a composite.
   - One unrelated indicator (91355, cancer emergency admissions) does publish at PCN level (AreaTypeID 204), which confirms Fingertips *can* carry PCN-level data generally — it's specifically ACSC-type measures that don't reach that far down.
3. Checked Fingertips `profiles()` for anything PCN- or primary-care-specific: **none exist.** There is no PCN-focused profile in Fingertips.
4. Checked whether NHS Digital publishes anything outside Fingertips at finer geography: the CCG OIS publication page on england.nhs.uk **404s** (retired), consistent with (2) above. GP registration data (needed for PCN population denominators) is still live and published (`digital.nhs.uk/.../patients-registered-at-a-gp-practice`, practice-level, poolable to PCN via ePCN mapping).

## Implication

There is no public, ready-made "ACSC admissions at PCN level" indicator. Three honest paths forward, in order of preference:

1. **Redefine the metric as a composite of the still-updated, ICB/sub-ICB-level condition indicators** (pneumonia, bronchiolitis, dementia, child gastroenteritis/LRTI admissions) and accept **ICB or sub-ICB as the finest usable geography** — this contradicts the brief's PCN-level ambition and needs a decision from you before Phase 1 starts.
2. **Look for a non-Fingertips public source** that publishes ACSC-type admissions at GP-practice or PCN level (e.g. NHS Digital's Hospital Episode Statistics summary tables, or an OHID/NHSE ad-hoc data release) — not yet checked; would need a further, narrower search.
3. **Drop PCN-level ACSC entirely** and pick a different metric that genuinely does publish at PCN level (Fingertips does support PCN as a geography — it's just not populated for ACSC-type measures) — a bigger pivot on the brief.

No patient-level data was touched — this was catalogue/metadata inspection only (indicator lists, area-type availability), not admissions figures themselves.

## Recommendation

Before writing any Phase 1 pipeline code: confirm which of the three paths above you want. Option 2 (a further, more targeted search for a non-Fingertips PCN-level ACSC source) is the only one that could still deliver the original brief as written, but isn't guaranteed to exist — worth a time-boxed check before falling back to option 1.
