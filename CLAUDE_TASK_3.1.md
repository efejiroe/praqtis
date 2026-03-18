# TASK DELEGATION: NHS Decision Intelligence Tool - Scrollytelling Narrative Refactor

**Role:** You are Claude Code, an expert Next.js/React Developer and UX Engineer.
**Supervisor:** You are acting under the architectural direction of the initial planning agent (Antigravity).

## 1. Context & Boundaries
You have successfully built the initial `web_app` for Task 3. However, following a strategic review with the GP Partner, the narrative flow has been significantly tightened to increase the "Shock Value" and make the behavioral fixes more actionable and grounded in the **EASY framework (East, Attractive, Social, Timely)**.

**Execute First:** Read the updated foundational documents in the `docs/` folder *before* rewriting any components:
* `docs/04_UX_Narrative.md` (Note the massive changes to View 4 and View 5).
* `docs/03_Logic_and_Metrics.md` (Note the removal of the QOF attrition metric and the addition of the "High-Risk Concentration" metric).
* `docs/01_PRD.md` (Note the emphasis on ROI and the EASY framework).

## 2. Your Immediate Objective
You must refactor the Next.js `page.tsx` (and any associated chart components) to exactly match the new 5-step airtight story flow: The Pain -> The Benchmark -> The Root Cause -> The Targeted Fix.

## 3. Step-by-Step Execution Plan

**STOP AND PLAN:** Write a short technical plan of which specific React components you will modify or replace to accommodate the new "Root Cause" Pareto chart and the "EASY Framework" checklist. Present this plan to the user/supervisor and wait for approval.

Once approved, execute the following steps:

### Step A: Replace the QOF/Causal Loop View
1. Delete or completely refactor the previous View 4 (The Causal Loop/QOF view).
2. Build the new **View 4: The Root Cause (The "Frequent Flyers")**.
3. Implement a new visual (e.g., a Pareto chart or a striking 80/20 text visual) that shows the user that their £4,000 loss is highly concentrated in a small, 15% high-risk cohort of their demographics, rendering universal SMS blasts ineffective.

### Step B: Refactor the Actionable Fixes
1. Rewrite **View 5: The Actionable Fixes**. 
2. Ensure the UI explicitly highlights the **ROI** (e.g., "Spending £1,000 on targeted interventions can halve your £4,000 deficit").
3. Structure the 3-point checklist explicitly using the **EASY framework** language found in the updated `04_UX_Narrative.md` (Social & Timely SMS, Easy Micro-commitments, Targeted Profiling).

### Step C: UI/UX Polish
1. Ensure the scroll transitions between View 3 (The Benchmark) -> View 4 (The Root Cause) -> View 5 (The EASY Fixes) feel like a continuous, undeniable thesis. 
2. Ensure the design remains strictly high-contrast and minimalist (NYT/Telegraph style), devoid of messy dashboard clutter.

## 4. Completion & Handoff
Once complete, run `npm run dev` to verify the new narrative flow is rendering correctly, check your terminal for errors, and report back to the supervisor.
