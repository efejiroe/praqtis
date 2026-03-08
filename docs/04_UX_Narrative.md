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

## View 4: The Unintended Consequence (Interactive Widget)
* **Visual (Scroll triggered):** An interactive line chart with a slider.
* **Text:** "How do you fix this? The traditional answer is to cram more appointments in to offset the loss. Let's see what happens if you do that."
* **Action:** User pulls the slider to increase "patients per day." The chart visually demonstrates the trap: "Rushed clinicians = confused patients = higher no-show rates next month."

## View 5: The Actionable Fix (Behavioral Nudges)
* **Visual:** A crisp, rigid 3-point checklist of easy-to-implement behavioral interventions.
* **Text:** "To reclaim this £[Lost Value], you need to change patient behavior, not work harder. Implement these 3 nudges today:"
    1. **Cost-Aware SMS:** Send reminders stating the financial cost ("Missing your appointment costs the NHS £40" or "Wastes dedicated clinical time").
    2. **Automated Follow-ups:** Enforce a 48-hour automated digital check-in after prescribing new chronic medication or high-value private treatments.
    3. **Delegation:** Shift routine reviews to allied health staff to free up doctors/dentists for complex cases.
