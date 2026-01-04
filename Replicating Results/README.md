# Step A: Replication of Experimental Results

This folder contains all scripts and results related to the **first step** of the roadmap: the exact reproduction of the main findings from Buchmann et al. (2023).

The objective is to validate the sample construction and estimator robustness before extending the analysis to heterogeneity (Step B).

## 📊 Key Result (Validation)

We successfully replicated the effect of the financial incentive on child marriage (Table 2 of the original article) with high precision.

| Metric | Original Article (Stata) | Our Replication (R) | Conclusion |
| :--- | :--- | :--- | :--- |
| **Incentive Effect** | **-0.049** (4.9 pp) | **-0.049** | ✅ Success |
| **Standard Error (SE)** | (0.010) | (0.010) | ✅ Success |
| **Sample Size** | N = 15,576 | N = 15,576 | ✅ Success |

> **Interpretation:** The financial incentive reduces the probability of marriage before age 18 by nearly 5 percentage points compared to the control group.

## 📂 Folder Structure

The analysis is sequential and organized as follows:

### 1. Data Preparation
* **`01_load_data.R`**:
    * Loading of raw data (`waveIII.dta`).
    * Cleaning and filtering to reconstruct the strict analytical sample ($N=15,576$).
    * Creation of treatment indicator variables.

### 2. Econometric Analysis
* **`02_replicating_tale.R`**:
    * Estimation of Linear Probability Models (LPM) with fixed effects.
    * Implementation of `fixest` for high-dimensional fixed effects (Union + Tercile) and clustering (Village).
    * Production of **Table 2** (Main Impact).

* **`03_Comparing_bras.R`**:
    * Generation of descriptive statistics and Balance Check.
    * Comparison of "naïve" means between treatment arms (Control, Incentive, Empowerment).
    * Production of **Table 1** (Randomization validation).

### 3. Visualization
* **`04_Vizualising.R`**:
    * Production of illustrative charts for the report.
    * Generation of confidence interval plots comparing treatment groups.

### 4. Outputs
* 📁 **`table/`**: Contains result tables exported in HTML/PNG format for integration into the final report.
* 📊 **Interactive Graph**: Visualisation of the impact across groups.

## 🛠️ Technical Methodology

* **Language:** R
* **Approach:** Strict replication of original econometric specifications.
* **Standard Errors:** Clustered at the village level (161 clusters), heteroskedasticity-robust.
* **Controls:** Age, Mother's education, Household size, Older sister indicator.

---
*Note: This module validates the foundations required for the heterogeneity analysis (Causal ML) conducted in Step B.*