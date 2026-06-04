# Step B: Heterogeneity Analysis & Policy Learning

This folder contains the **Machine Learning extension** of the replication project.
While Step A estimated the *Average* Treatment Effect (ATE), this module uses **Causal Forests** to estimate *Conditional* Average Treatment Effects (CATE) at the individual level.

The goal is to answer two policy questions:
1.  **Heterogeneity:** Does the incentive work for everyone, or are there "winners" and "losers"?
2.  **Policy Targeting:** Can we optimize the program's efficiency by targeting specific subgroups?

## 📊 Executive Summary (Key Results)

Using a Generalized Random Forest (GRF) trained on baseline covariates, we found significant heterogeneity masked by the average effect.

| Metric | Result | Interpretation |
| :--- | :--- | :--- |
| **Global ATE (Forest)** | **-4.3 pp** | consistent with OLS results (-4.9 pp). |
| **Targeting Rule** | **Treat if CATE < 0** | Excludes ~19% of girls with null/negative response. |
| **Optimal Target Size** | **81.06%** | The vast majority benefits, but not everyone. |
| **GATE (Targeted)** | **-6.28 pp** | Effect on the targeted group. |
| **Efficiency Gain** | **+45.1%** | Relative improvement of impact vs. universal rollout. |

> **Key Insight:** Targeting the "Best Responders" (mostly girls currently in school) increases the program's impact per treated unit by **45%** compared to a "spray and pray" approach.

## 📂 Script Guide

The analysis is broken down into three sequential scripts:

### 1. Data Preparation (`01_ml_prep.R`)
* **Sub-sampling:** Restricts analysis to **Incentive vs. Control** arms (excluding Empowerment).
* **Feature Engineering:** Selects strict *baseline* covariates to avoid "bad controls".
    * *Variables used:* Age, Mother's Education, Household Size, Older Sister dummy, Schooling status, etc.
* **Formatting:** Handles missing values (imputation) and converts data to numeric matrices required by the C++ backend of `grf`.

### 2. Causal Forest Estimation (`02_causal_forest.R`)
* **Algorithm:** Trains a Causal Forest using the `grf` package (Athey, Tibshirani & Wager, 2019).
* **Parameters:** 3,000 trees to ensure stability of CATE estimates.
* **Output:** Generates the distribution of individual effects (CATE) and validates the model against the aggregate ATE.
* **Visualization:** Plots the heterogeneity distribution (check `output/cate_distribution.png`).

### 3. Policy Analysis (`03_policy_analysis.R`)
* **Profiling:** Compares characteristics of "Best Responders" (Top Quartile) vs. "Least Responders" (Bottom Quartile).
    * *Finding:* Response is strongly correlated with baseline school enrollment.
* **Policy Value:** Calculates the optimal targeting ratio and the theoretical efficiency gain (GATE vs. ATE).

## 🛠️ Methodology & Technical Details

* **Method:** Generalized Random Forests (Honest Estimation).
* **Software:** R package `grf` version 2.x.
* **Identification Assumption:** Unconfoundedness (guaranteed by the RCT design).
* **Handling of NAs:** List-wise deletion for Outcome/Treatment; Mean imputation for Covariates (as standard in Tree-based models).

---
*For the replication of the main experimental tables, please refer to the `replicating_results` folder.*