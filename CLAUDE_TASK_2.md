# TASK DELEGATION: NHS Data Pipeline Transform & Data Science Phase

**Role:** You are Claude Code, an expert Data Engineer and Python Developer. 
**Supervisor:** You are acting under the architectural direction of the initial planning agent (Antigravity).

## 1. Context & Boundaries
You have successfully completed the extraction phase for NHS Appointments data. Now, we must move on to the remaining Extraction and the Data Science Transformation phase exactly as outlined in `02_Architecture.md` and `03_Logic_and_Metrics.md`. 
**Constraint Checklist:** 
* NO Database configurations. Must output to flat JSON static files.
* Python code should be clean, modular, and use well-known libraries (pandas, scikit-learn).
* GitHub Action must be updated to commit the JSON files back to the repository.

## 2. Your Immediate Objective
Your task is to fetch the remaining datasets (Demographics and QOF), join them with the Appointments data, calculate the metrics, run a K-Means clustering algorithm to create practice "Archetypes," and output a lightweight `data.json` file.

## 3. Step-by-Step Execution Plan

**STOP AND PLAN:** Before executing Step A, B, or C, you must write a short, bulleted technical plan of the exact libraries, dataset logic, and clustering approach you intend to use. Present this plan to the user/supervisor and wait for explicit approval to begin coding.

**TOKEN MODULARITY RULE:** You are instructed to work in focused sprints. Do not attempt all steps simultaneously. At the end of Step A, output a summary and explicitly check in with the user (e.g., "Step A completed. Awaiting permission to begin Step B."). 

Once your plan is approved, please execute the following steps sequentially:

### Step A: Fetch Remaining Datasets
1. Expand your existing Python scraper (or create specific helper modules in `data_pipeline/`) to additionally fetch two more public NHS CSVs:
    - **Patients Registered at a GP Practice** (to get List Size and LSOA/Demographics for clustering).
    - **Quality and Outcomes Framework (QOF)** (to get performance scores for the Attrition Risk metric).
2. Download these files to `data_pipeline/raw_data/`.
3. Add any necessary unzipping logic to process the downloads.

### Step B: The Data Science Transformation
1. Create a script named `transform_data.py`.
2. Load the CSVs using `pandas`.
3. Join them on the GP Practice ODS Code.
4. Calculate the base metrics (DNA Rate %, Wasted Capacity £).
5. **Clustering:** Use `scikit-learn` (add to `requirements.txt`) to run a K-Means clustering algorithm. 
    - Features: List Size, DNA Rate, Demographics proxy.
    - Output: Assign an "Archetype" cluster ID to every practice.
6. Calculate the "Benchmark Gap": Map each practice's DNA rate against the Top 10% performers *only* within its own Archetype cluster.

### Step C: Load & GitHub Action Automation
1. The script must output the final processed dataset as a lightweight file: `data_pipeline/output/practice_data.json`.
2. Update `.github/workflows/nhs_etl_pipeline.yml` to include the new script in the run order:
    - `python data_pipeline/scrape_appointments.py` (updated to get all data)
    - `python data_pipeline/transform_data.py`
3. Add a final step to the GitHub Action YAML to commit the `output/practice_data.json` file back into the GitHub repository using standard git config commands.

## 4. Completion & Handoff
Once complete, run a local test of `transform_data.py` to ensure the final JSON file is correctly formatted and contains the Archetype clusters and Benchmark Gap metrics. Report back to the supervisor when done.
