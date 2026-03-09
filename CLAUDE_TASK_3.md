# TASK DELEGATION: NHS Decision Intelligence Tool - Front-End App

**Role:** You are Claude Code, an expert Next.js/React Developer and UX Engineer.
**Supervisor:** You are acting under the architectural direction of the initial planning agent (Antigravity).

## 1. Context & Boundaries
You have a fully operational Data Pipeline that automatically outputs a `data.json` file into the `data_pipeline/output/` directory containing clustered NHS Practice data (DNA Rates, Wasted Capacity, Archetype identifiers).

Your task is to now build the web application that reads this file and presents the data to the user.

**Execute First:** Read the following foundational documents in the `docs/` folder *before* writing any code:
* `04_UX_Narrative.md` (The exact screen-by-screen flow).
* `docs/_HANDOVER.md` (Read the Hard Constraints section regarding REPLIQR branding and the "anti-dashboard" aesthetic).
* `03_Logic_and_Metrics.md` (So you understand the math behind the numbers you are rendering).

**Constraint Checklist:** 
* Frame: Next.js + Tailwind CSS.
* Format: Static generation (SSG) reading directly from the `data.json` file. No database connections API routes needed.
* Aesthetic: High-contrast, minimalist, "Data Journalism" / "Scrollytelling" style (Think NYT or The Telegraph interactive articles).
* Animation: Use GSAP (ScrollTrigger) or Framer Motion to animate the text reveals and chart builds as the user scrolls.

## 2. Step-by-Step Execution Plan

**STOP AND PLAN:** Before executing Step A, B, or C, write a short technical plan of your chosen libraries (e.g., Framer vs GSAP, Recharts vs D3), folder structure, and component layout. Present this plan to the user/supervisor and wait for explicit approval to begin coding.

**TOKEN MODULARITY RULE:** You are instructed to work in focused sprints. Do not attempt all steps simultaneously. At the end of Step A, output a summary and explicitly check in with the user (e.g., "Step A completed. Awaiting permission to begin Step B."). 

Once your plan is approved, please execute the following steps sequentially:

### Step A: Initialize Next.js Application
1. Run `npx create-next-app@latest web_app` inside the root `praqtis` directory.
    - Select TypeScript, Tailwind CSS, App Router.
2. Ensure you clean up standard boilerplate files in `app/page.tsx` and `globals.css` to give us a stark, minimalist black/white/high-contrast foundation.
3. Install necessary animation and charting dependencies (`framer-motion` or `gsap`, `recharts` or `d3`).
4. Copy the `data_pipeline/output/practice_data.json` file into the `web_app/public/data/` directory so it can be fetched statically by the Next.js app on load.

### Step B: Build the Core Components (The Narrative)
Review `04_UX_Narrative.md` again. Build a single, scrolling `page.tsx` that stitches together 5 distinct views as React components:
1. **The Hook View:** A massive input field to search for the GP Practice.
2. **The Reveal View:** A massive count-up animation of the `Wasted Capacity £`.
3. **The Context View:** A horizontal bar chart or dot-plot showing the chosen practice compared to the Top 10% average of its specific `Archetype` cluster (The Benchmark Gap).
4. **The Causal Loop View:** An interactive line chart slider demonstrating how cramming more appointments (X-axis) linearly increases the DNA rate (Y-axis) due to poor patient understanding.
5. **The Actionable Fix View:** A rigid, well-designed 3-point checklist of Nudge Interventions.

### Step C: Polish & Interaction (Scrollytelling)
1. Add the ScrollTrigger/Intersection Observer hooks so that as the user scrolls down, View 2, 3, and 4 fade in and the charts animate drawing themselves.
2. Do NOT present this as a dense dashboard. Each View should take up roughly `100vh` (a full screen), hiding the next section until the user scrolls.

## 3. Completion & Handoff
Once complete, run `npm run dev` in the `web_app` directory, test the app locally to ensure the data is parsing correctly, and report back to the supervisor.
