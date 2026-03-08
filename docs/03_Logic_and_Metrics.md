# The Logic & Metrics (Math & System Dynamics)

## The Core Calculations
The tool needs hard numbers to create "Shock Value" for the user. These formulas translate standard NHS data into real financial and operational pain.

### Metric 1: The Cost of Wasted Capacity (or Lost Revenue)
* **Formula:** `(Number of monthly DNAs for Practice X) * (Average Appointment Value)`
* **Interpretation (NHS GP):** "You lost £[Wasted Capacity] in clinical time last month." (Using the £40 estimated NHS cost of a missed 10-minute appointment).
* **Interpretation (Private/Dental):** "You lost £[Lost Revenue] in uncaptured private fees last month." (Using their average private consultation or treatment value).

### Metric 2: The Benchmark Gap (Using Data Science)
* **Goal:** Calculate the difference between the user's practice and the Top 10% of practices *in their exact Archetype cluster*.
* **Formula:** `(User DNA Rate%) - (Top 10% Cluster Average DNA Rate%) = Gap%`
* **Interpretation:** "Compared to 150 urban practices with the exact same patient demographics, your DNA rate is [Gap%] worse."

### Metric 3: The Attrition Risk (QOF or Private Treatment Plans)
* **Goal:** Show the money at risk due to missed chronic reviews or unaccepted private treatment plans.
* **Interpretation (NHS GP):** "Missed chronic reviews are putting an estimated £[X] of your annual QOF bonus at risk."
* **Interpretation (Private/Dental):** "Your current follow-up drop-off rate is putting £[X] of diagnosed private treatment plans at risk of never being scheduled."

## 2. Nudge Theory & Unintended Consequences (The Causal Loop)
The tool must contain an interactive widget that explains *why* the standard fix fails, using basic behavioral principles.

**The Flawed Strategy (Unintended Consequences):**
When capacity is tight because of DNAs, practices try to cram more appointments into a schedule. 
1. *Variable A (Appointments per day) goes UP.*
2. *Variable B (Consultation length) goes DOWN.*
3. *Variable C (Patient understanding/Relationship) goes DOWN.*
4. *Variable D (DNA rate / Non-Adherence) goes UP.* (The patient feels rushed, doesn't understand the plan, and doesn't come back for the chronic review).

**The Interactive Element:** 
A slider on the screen ("What if I try to push 5 more patients a day through the clinic?"). The UI visualizes the short-term drop in wait times, but the long-term spike in the DNA rate and staff burnout due to the Causal Loop.
