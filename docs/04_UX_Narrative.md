# UX Narrative Flow ("Scrollytelling")

This document dictates what the user actually sees on their screen. The design should mimic an interactive data journalism article (e.g., The Telegraph or NYT), not a typical web app. **All visual elements must strictly adhere to REPLIQR branding rules.**

## View 1: The Hook (Input)
* **Visual:** Clean, bold minimalist landing page. Large impact statement.
* **Text:** "How much is patient non-adherence really costing your practice?"
* **Action:** 1 input field: "Enter your GP Practice ODS Code, Postcode, or select your Practice Type (Private/Dental)." 
* **Submit:** "Generate My Benchmark" button.

## View 2: The Reveal (The Big Number)
* **Visual:** The screen wipes clean. A massive, bold number counts up from £0 to the final amount.
* **Text:** "Based on public data, your practice lost an estimated **£[Wasted Capacity / Lost Revenue]** to missed appointments or follow-ups last month."

## View 3: The Context (Clustered Benchmarking)
* **Visual (Scroll triggered):** A simple dot-plot or horizontal bar chart animates into view.
* **Text:** "A DNA rate of **[User%]** looks bad. But let's look at the context. We compared you only against practices that look exactly like yours (similar size and local demographics). Compared to the top 10% of your exact peers, you are underperforming by **[Gap%]**."

## View 4: The Root Cause (The "Frequent Flyers")
* **Visual (Scroll triggered):** A Pareto chart or a visual representation of a patient list.
* **Text:** "Why are you worse than your peers? Because you are treating all your patients the same. Based on the deprivation index of your patient list, **[X%]** of those £4,000 losses were likely caused by a core **[Y%]** of chronic 'frequent flyer' patients. Automated SMS systems do not work on this cohort."

## View 5: The Actionable Fix (The EASY Framework)
* **Visual:** A crisp, rigid 3-point checklist of easy-to-implement behavioral interventions based on the EASY framework.
* **Text:** "To reclaim this £[Lost Value], you don't need new software. You already have automated messaging—use it differently. The ROI is immediate: spending £1,000 on targeted SMS can halve your £4,000 monthly deficit. Implement these 3 nudges today:"
    1. **Social & Timely (Re-write your SMS):** Stop sending generic reminders. Update your accuRx/EMIS templates to introduce a social cost ("Missing your appointment wastes £40 of dedicated clinical time"). 
    2. **Easy (The 48-Hour Micro-Commitment):** Don't wait 3 months for a review. Make it *Easy* for the patient to engage by setting your system to send an automated digital check-in 48 hours after prescribing new medications ("Have you picked up your prescription? Y/N").
    3. **Targeted (Predictive Profiling):** Stop texting everyone equally. Use your EMIS filters to identify patients with ≥2 previous DNAs. Divert these specific "high-risk" cohorts away from automated SMS entirely, and trigger a proactive 30-second human phone call. The human touch drastically reduces non-adherence for the most prone patients.
