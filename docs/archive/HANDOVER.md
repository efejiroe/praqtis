# Project Handover: NHS GP Decision Intelligence Tool

## Executive Summary
We are building a highly targeted "scrollytelling" interactive web tool for healthcare practices (including NHS General Practices, Private Medical Clinics, and Dental Practices). Its goal is to benchmark a practice against identical peers using public data and calculate the operational/financial cost of **patient non-adherence** (missed appointments, lost follow-ups, and lost bonus targets). 

* **The audience:** NHS GP Partners, Private Medical Practice Managers, and Dental Practice Owners.
* **The purpose:** To prove immediate value, highlight hidden losses, and offer actionable solutions as a powerful lead-generation tool.

## The Roadmap (Read Me First)
Before writing any code or designing any interfaces, you must read the following 4 foundational documents in order to understand the strict boundaries for this project:

1. `01_PRD.md` (Product Requirements Document: The Who, What, and Why)
2. `02_Architecture.md` (The Data Pipeline & Tech Stack)
3. `03_Logic_and_Metrics.md` (The Math & Causal Loops to calculate losses)
4. `04_UX_Narrative.md` (The Screen-by-Screen User Journey)

## Hard Constraints (Guardrails)
* **NO Private APIs:** Use ONLY public, downloadable data from NHS Digital (Appointments, QOF, List Sizes).
* **NO Database Servers:** The data pipeline must be fully serverless, running on GitHub Actions via Python to clean CSVs and generate flat JSON files.
* **NO Dashboard Aesthetic:** The user interface must read like a polished article or story (e.g., The Telegraph), not a typical clinical dashboard. Keep cognitive load low. Design must strictly adhere to the **REPLIQR branding rules** (to be provided at the start of development).

## Current Status & Next Steps
* **Status:** Ideation and architecture rules are finalized. Data sources have been identified.
* **Next Immediate Task for the Developer/Agent:** Refer to `02_Architecture.md`, and write the Python script that runs on a scheduled GitHub Action to scrape the latest "Appointments in General Practice" CSV from NHS Digital.
