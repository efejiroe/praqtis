# TASK DELEGATION: NHS Data Pipeline Initialization

**Role:** You are Claude Code, an expert Data Engineer and Python Developer. 
**Supervisor:** You are acting under the architectural direction of the initial planning agent (Antigravity).

## 1. Context & Boundaries
Before you write any code, you MUST establish context by reading the project handover document. 
**Execute:** Read `docs/_HANDOVER.md` located in the root of this workspace. 
*Do not proceed until you have read and understood the constraints (e.g., Serverless only, GitHub Actions, No databases).*

## 2. Your Immediate Objective
Your task is to build the Extract phase of our ETL pipeline. We need a Python script that automatically checks the NHS Digital website for the latest "Appointments in General Practice" publication and downloads the primary CSV data file.

## 3. Step-by-Step Execution Plan

**STOP AND PLAN:** Before executing Step A, B, or C, you must write a short, bulleted technical plan of the exact libraries, URL targets, and folder structures you intend to use. Present this plan to the user/supervisor and wait for explicit approval to begin coding.

Once approved, please execute the following steps sequentially, asking for user approval to run shell commands where necessary:

### Step A: Git & Project Initialization
1. Check if the current directory (`PRAQTIS`) is already a git repository.
2. If it is NOT a git repository, initialize it (`git init`).
3. Use the GitHub CLI (`gh repo create`) or standard git commands to create a new private remote repository on the user's GitHub account and push the initial foundational documents to it. **Ask the user for the preferred repository name before creating it.**
4. Create a directory named `data_pipeline` in the root of the project.
5. Inside `data_pipeline`, initialize a new Python project/virtual environment. 
6. Create a `requirements.txt` file including only what is necessary for web scraping and data manipulation (e.g., `requests`, `beautifulsoup4`, `pandas`).

### Step B: The Scraper Script
1. Create a file named `scrape_appointments.py` inside `data_pipeline`.
2. Write a Python script that targets the NHS Digital publications page (Search query logic or direct URL pattern for "Appointments in General Practice").
3. The script needs to find the link to the most recent month's CSV file (usually containing practice-level appointment data).
4. The script should download this CSV into a local folder named `data_pipeline/raw_data/`.
5. *Constraint Checklist:* Ensure the script handles potential HTML structure changes gracefully (use robust CSS selectors or regex) and includes basic error logging (e.g., checking HTTP status codes).

### Step C: The Serverless Automation (GitHub Actions)
1. Create the `.github` directory structure: `.github/workflows/`.
2. Create a file named `nhs_etl_pipeline.yml` inside the workflows folder.
3. Write a GitHub Actions YAML configuration that:
    - Triggers on a schedule (cron: e.g., '0 0 15 * *' - 15th of every month).
    - Can also be triggered manually (`workflow_dispatch`).
    - Checks out the repository.
    - Sets up Python 3.x.
    - Installs dependencies from `data_pipeline/requirements.txt`.
    - Runs `python data_pipeline/scrape_appointments.py`.
    - (Future Step placeholder) Commits any downloaded/changed data back to the repository.

## 4. Completion & Handoff
Once you have written the script and the GitHub Action YAML:
1. Run a test of `scrape_appointments.py` (ask the user for permission to execute it locally) to verify it successfully downloads a CSV.
2. Report the results back to the user and yield control back to the supervisor agent.
