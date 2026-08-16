# Task log

Running checklist of completed work on this project, kept so a session
tomorrow (or a different session) has a quick record of what's already
been done and why, without re-deriving it from `git log` or conversation
history. Newest entries at the top. Each entry links the commit where
one exists.

## 2026-08-16

- [x] **Added DNA (Did Not Attend) rate and a practice-level drill-down**
      as internal diagnostics — explicitly NOT in the client-facing
      report (confirmed with the user: report shows the ARRS staffing
      disclosure only; DNA and the drill-down are for our own
      investigation, or a follow-up call if a prospect engages).
      - New `src/fetch_dna.R` (`fetch_practice_dna()`) — NHS Digital
        GPAD "Appointments in General Practice" June 2026 crosstab,
        verified live (HTTP HEAD) and then actually downloaded and
        inspected before writing any parsing code, per this project's
        "verify empirically, don't assume" rule. Real schema differs
        from other sources' conventions: practice code column is
        `GP_CODE` (not `PRACTICE_CODE`/`PRAC_CODE`), status column
        `APPT_STATUS` takes exactly `Attended`/`DNA`/`Unknown`.
      - `practice_dna_rate()`/`pcn_dna_rate()` (src/aggregate_pcn.R) —
        sum-then-divide throughout (never averaging per-row/per-practice
        rates), to avoid Simpson's-paradox-style bias when rolling up.
      - `practice_staffing_snapshot()` + `practice_pcn_drilldown()` — the
        practice-level "why" behind a PCN-level flag: each constituent
        practice's staffing intensity and DNA rate vs. the *rest* of its
        PCN (excluding itself, confirmed with user — matches the old
        deleted `practice_vs_pcn()`'s approach). Explicitly excludes ARRS
        FTE from the practice split (PCN-native, no practice-level
        equivalent — stated in code comments, not silently omitted).
        Deliberately not a registered target — parameterised per-PCN,
        called ad hoc, same pattern as the report's own
        `params$pcn_code` filtering.
      - Verified end-to-end: national DNA rate distribution is plausible
        (median 4.2%, mean 4.6%), 1,296 of 1,298 PCNs and 6,119 of 6,139
        practices have DNA coverage, and the Heritage PCN (`U24992`)
        worked example cross-checks exactly against
        `national_pcn_workforce`/`national_pcn_dna_rate` — surfaced a
        real, plausible finding: one constituent practice is staffed
        135% above the rest of its PCN.
      - No changes to `national_staffing_model`/
        `national_staffing_funnel_flags`/`national_staffing_model_comparison`
        — both capabilities are purely additive, confirmed with the user
        DNA should NOT become a model covariate (circularity risk: it's
        plausibly a symptom of the same understaffing the model already
        measures, and folding it in would break comparability with the
        Mukhtar et al. 2018 literature check).
- [x] **Clarified CLAUDE.md's money-estimate rule.** User asked whether
      caveated £ estimates should be allowed in the pitch report.
      Recommended and applied a distinction: *actual* PCN spend/
      underspend claims stay forbidden (no public source below ICB
      level — unchanged), but *modelled capacity estimates* built
      transparently from published inputs (e.g. the national ARRS
      £-per-contractor-weighted-patient rate × a PCN's own official
      weighted population, per `ref/concept_note.md`'s financial-capacity
      benchmark) are now explicitly allowed in the report, provided
      they're always labelled as estimates/ranges, never a single
      precise number implying a factual claim.
- [x] **Added a credibility line** (user's request: "our model uses 2026
      data and is benchmarked with Mukhtar's results" should read as a
      confidence signal) to `report/pcn_report.qmd` (after the funnel
      chart) and `ref/concept_note.md` (Value proposition + the Example
      buyer message quote) — deliberately a clean claim, no caveat, per
      explicit user direction after being shown the tradeoff (the
      Limitations section's honest, caveated account of the age-effect
      divergence stays as-is and unchanged; this is an additional
      confidence note elsewhere, not a replacement for it).
- [x] **Found `ref/CONCEPT.md` no longer exists.** The file this session
      had been reading/editing all of 2026-08-15 as "the concept note" is
      gone from disk (never git-tracked — `ref/` is gitignored, so no
      history to recover from). In its place: `ref/concept_note.md`, a
      genuinely different, real document — a business concept note
      (title "REPLIQR") the user had apparently been developing
      separately. Confirmed with the user this is the real, current file;
      all concept-note work from here on targets it, not the old path.
- [x] **Renamed "PRAQTIS" and "REPLIQR" → "PCN-ARRS"**, at the user's
      request, converging both names onto one brand — `README.md` title,
      `report/pcn_report.qmd` YAML title, `CLAUDE.md` Context line,
      `ref/concept_note.md` title + 4 body references. Left one
      "PRAQTIS/" reference in `CLAUDE.md` (constraints, re: the parent
      folder) untouched — it's an actual filesystem path
      (`C:/Users/efeji/Projects/PRAQTIS/`), not brand usage; renaming the
      text without renaming the folder would just make it wrong. Also
      fixed several stale `ref/CONCEPT.md` path references left over from
      the file-identity mixup (`CLAUDE.md`, `report/pcn_report.qmd`,
      `src/fetch_workforce.R`) to point at `ref/concept_note.md`.
- [x] **Corrected course on the age-weighting model**, after the user
      pushed back on 2026-08-15's approach: they hadn't objected to
      self-fitting per se, just to not knowing where weights came from —
      their default preference is a regression on our own data. Walked
      back the literature-RR-as-production-weights design from earlier
      today and rebuilt as: self-fitted model stays the production
      "expected FTE" (unchanged in spirit from 08-15), but now a proper
      Poisson GLM (`glm(family = "poisson")`, population-composition
      shares as covariates, `list_size` as the exposure offset) instead
      of the old `lm()` — matches FunnelPlotR's own documented usage
      pattern, and was the user's own instinct
      ("I thought we just had to do Poisson regression").
- [x] **Extended the model with more variables**: sex and IMD quintile
      (population-weighted, quintiled at *practice* level so a PCN
      blending a deprived and an affluent practice gets genuine mixed
      quintile shares, not one misleading average), alongside age — all
      three self-fitted, none imported.
- [x] **Retrieved and verified a genuine open-access literature source**
      to check the self-fit against (after Carr-Hill's exact table again
      proved unobtainable — same paywall/bot-block problems as 08-15):
      Mukhtar TK, Bankhead C, Stevens S, Perera R, Holt TA, Salisbury C,
      Hobbs FDR, "Factors associated with consultation rates in general
      practice in England, 2013-2014," *Br J Gen Pract*
      2018;68(670):e370-e377, DOI 10.3399/bjgp18X695981 (CC BY-NC 4.0) —
      read in full from a working PDF mirror, exact rate ratios by age
      band/sex/IMD quintile transcribed and verified. Added
      `national_model_comparison()` (src/compute_funnel.R) as an internal
      diagnostic (`tar_read()`-able, not surfaced in the client report)
      comparing our fitted rate ratios against this paper's, on a
      like-for-like basis (matching reference categories, and re-basing
      the paper's finer age bands onto our coarser ones by
      population-weighting).
- [x] **Hit and fixed a real collinearity bug.** First attempt matched
      Mukhtar's 7 fine age bands exactly (for the cleanest possible
      comparison) — badly unstable at ~1,300 PCN observations: one
      elderly coefficient came out as a 300x rate ratio with a 95% CI
      spanning 33x-2706x, a fitting artefact, not a real effect. Fixed by
      coarsening age back to 3 bands (under-15/15-64/65+, same shape as
      08-15's original model) — stable, all coefficients now have sane,
      tight CIs.
- [x] **The actual comparison result** (`national_staffing_model_comparison`
      target): deprivation terms corroborate closely with Mukhtar's
      published figures (IMD quintiles 2 and 5 match almost exactly).
      Age terms diverge substantially and with statistical confidence —
      our fitted 65+ rate ratio (~8.2x) is roughly 4-5x higher than the
      literature's rebased figure (~1.7x), CI doesn't overlap. Plausible
      explanation, not confirmed: Mukhtar measures consultation *rate*
      (demand, 2013-14); this pipeline measures actual FTE *deployed*
      (supply, 2026) — PCNs may genuinely weight ARRS deployment toward
      older populations more heavily than raw consultation volume alone
      would predict. Left as an open question in `ref/concept_note.md`,
      not resolved.
- [x] **Rebuilt and re-rendered** the report against everything above;
      confirmed clean. New PCN-ARRS report PDF sent to the user.

## 2026-08-15

- [x] **Report copy: dropped "ROS" everywhere it was unexplained.**
      "ROS" (Recruitment Opportunity Score) appeared in the rendered
      report with no definition — confusing to a reader who hadn't seen
      the working name. Rewrote reader-facing copy in plain language
      instead.
- [x] **Found the underlying ROS score was dead code.** The funnel
      check never actually read the `ros` ranking value
      (`list_size * imd_score / total FTE`) — it derives actual/expected
      FTE independently. Removed the score entirely and renamed
      everything that referenced it (`compute_ros.R` → `compute_funnel.R`,
      `pcn_ros()` → `pcn_staffing_need()`, `national_pcn_ros_funnel[_flags]`
      → `national_staffing_funnel[_flags]`). Also deleted a stray
      gitignored `dat/out/ros_funnel_outlier_pcns.csv` left over from an
      earlier session.
      → [a670d0a](https://github.com/efejiroe/praqtis/commit/a670d0a) Remove ROS terminology; drop dead ranking score
- [x] **Rebuilt the pipeline and re-rendered the report** against the
      renamed targets — confirmed `targets::tar_make()` and
      `quarto render` both succeed end to end (R and Quarto are
      available locally at `C:/Program Files/R/R-4.6.1` and
      `C:/Program Files/Quarto`).
- [x] **Literature check: is list size × IMD the right thing to adjust
      for?** Researched Spiegelhalter (2005) funnel-plot methodology
      (solid — that part's standard) and NHS/academic literature on
      GP-practice need-adjustment (Carr-Hill formula; 2021 BJGP Open
      workforce-inequality study; 2024 BJGP Open/ScienceDirect
      deprivation-formula study). Finding: deprivation alone
      measurably under- and over-states need — age structure is a
      known, evidenced gap; morbidity is a second, unaddressed one.
- [x] **Built age-weighting into the funnel check.** Added
      `pcn_age_bands()` (src/aggregate_pcn.R) pooling the 5-year
      AGE_GROUP_5 breakdown already present in the registration data
      (previously fetched and discarded) into three PCN-level bands:
      under-15, 15–64, 65+. Tried to source NHS England's Carr-Hill
      age-sex coefficient table to reuse directly — couldn't retrieve or
      verify the actual numeric table from any public source tried
      (SFE directions, BMA/LMC guidance, formula-review paper — all
      paywalled, bot-blocked, or didn't surface the table in extraction).
      Fit our own three-band weights from national data instead (OLS, no
      intercept) — verified empirically: R² rises from 0.78 to 0.96 vs.
      list size × IMD alone, all three coefficients non-negative (no PCN
      can get a negative expected FTE), elderly coefficient ~4.5× the
      working-age one — directionally consistent with the literature.
      Flagged the one weak spot honestly: the under-15 coefficient isn't
      itself statistically significant (likely because that band merges
      high-need under-5s with low-need 5–14s).
- [x] **Updated report, README, CLAUDE.md, ref/CONCEPT.md** to describe
      the age-adjusted model, document why weights were fitted rather
      than imported, and note morbidity as the next evidenced gap.
      Rebuilt and re-rendered; diffed `ref/CONCEPT.md` before/after for
      the user.
- [x] **Created this file** at the user's request, to log completed
      tasks going forward.

## Earlier (same session, prior to this log's creation)

- [x] Trimmed report to MVP scope: fetch → aggregate → national funnel
      check only. Removed PPD (`src/compute_ppd.R`), the practice-level
      drill-down (`src/lookup_practice.R`), and the QOF fetch/data they
      depended on.
      → [23befe6](https://github.com/efejiroe/praqtis/commit/23befe6) Trim pipeline to MVP
- [x] Removed the IIF/TPG pipeline (appointments-access threshold check)
      entirely, making the ROS/staffing national funnel plot the
      report's sole outlier-detection method.
      → [ded19c4](https://github.com/efejiroe/praqtis/commit/ded19c4) Remove IIF/TPG pipeline
- [x] Rewrote the report to lead on the staffing funnel-plot outlier
      check rather than TPG.
      → [75d9701](https://github.com/efejiroe/praqtis/commit/75d9701) Phase 3: lead on ROS staffing-outlier funnel

## Not yet done / open

- [ ] Commit and push the working tree — nothing from 2026-08-15 or
      2026-08-16 has been committed yet (age-weighting, ROS cleanup, MVP
      trim, the Poisson-model rework, and the PRAQTIS/REPLIQR → PCN-ARRS
      rename are all still uncommitted).
- [ ] The age-vs-consultation-rate divergence found in today's literature
      comparison (~8x vs ~1.7x for the 65+ band) is flagged as an open
      question, not investigated further — worth a closer look before
      this goes anywhere client-facing.
- [ ] Add a morbidity proxy to the need-adjustment model — flagged as a
      gap by every source found in both literature checks (08-15 and
      08-16), not addressed yet (QOF disease-register prevalence was
      fetched at one point but was descoped along with PPD; would need
      re-adding if this is picked up).
- [ ] `ref/concept_note.md`'s own MVP scope section still says "Defer
      regression-based expected values ... until the paid diagnostic
      phase" — now inconsistent with what's actually been built (a
      regression is already the funnel check's core). Noted in today's
      revision-log entry there, but the MVP scope section itself wasn't
      rewritten to match.
- [ ] Phase 4 validation (per CLAUDE.md roadmap): render for one PCN
      with a real contact who can check it before any batch-rendering.
