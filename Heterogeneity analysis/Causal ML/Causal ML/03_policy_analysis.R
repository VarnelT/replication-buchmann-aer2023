library(tidyverse)
library(gt)
library(patchwork)

# --- 1. CHARGEMENT DES RÉSULTATS CATE ---
df_results <- readRDS("data/df_cate_results.rds")

# --- 2. DÉFINITION DE LA "POLICY RULE" ---
# La règle : On traite si l'effet prédit est bénéfique (réduction du mariage).
# Comme l'outcome est négatif (mariage), un effet "bénéfique" veut dire CATE < 0.
# (On peut mettre un seuil plus strict, ex: < -0.01, mais < 0 est le standard théorique).

df_policy <- df_results %>%
  mutate(
    # Segmentation : "Strong Responder" (Top 25% effet) vs "Weak/Negative Responder"
    # Attention : "Plus fort" effet veut dire "Plus Négatif"
    cate_quartile = ntile(cate, 4), # 1 = Les plus négatifs (Best), 4 = Les plus positifs (Worst)
    
    classification = case_when(
      cate_quartile == 1 ~ "Best Responders (Strong Reduction)",
      cate_quartile == 4 ~ "Least Responders (No Effect/Perverse)",
      TRUE ~ "Average Responders"
    ),
    
    # La décision binaire de ciblage
    should_treat = if_else(cate < 0, "Target", "Do Not Target")
  )

# --- 3. TABLEAU DES CARACTÉRISTIQUES (QUI SONT LES BEST RESPONDERS ?) ---
# Crépon demande : "Tableau des sous-groupes les plus affectés"
# On compare les caractéristiques moyennes des "Best" (Quartile 1) vs "Worst" (Quartile 4)

table_profiling <- df_policy %>%
  filter(classification %in% c("Best Responders (Strong Reduction)", "Least Responders (No Effect/Perverse)")) %>%
  group_by(classification) %>%
  summarise(
    N = n(),
    Avg_Effect_CATE = mean(cate),
    Age = mean(bl_age_reported),
    Mother_Edu = mean(bl_education_mother),
    HH_Size = mean(bl_HHsize),
    Sister_Married = mean(older_sister),
    School_Baseline = mean(bl_still_in_school)
  ) %>%
  pivot_longer(cols = -classification, names_to = "Variable", values_to = "Value") %>%
  pivot_wider(names_from = classification, values_from = Value)

# Mise en forme avec GT
gt_tbl <- table_profiling %>%
  gt() %>%
  tab_header(
    title = "Characteristics of Most vs. Least Affected Groups",
    subtitle = "Heterogeneity Analysis using Causal Forest"
  ) %>%
  fmt_number(columns = where(is.numeric), decimals = 2) %>%
  tab_style(
    style = list(cell_text(weight = "bold")),
    locations = cells_body(columns = Variable)
  )

print(gt_tbl)
gtsave(gt_tbl, "Heterogeneity analysis/Causal ML/Causal ML/Table_Heterogeneity_Profile.html")

# --- 4. POLICY VALUE FUNCTION (LE CHIFFRE CLÉ) ---
# Quelle proportion de la population doit-on cibler ?

prop_target <- mean(df_policy$should_treat == "Target")
n_target <- sum(df_policy$should_treat == "Target")

cat("\n--- RÉSULTATS POLICY VALUE ---\n")
cat("Proportion de filles à cibler (CATE < 0) : ", round(prop_target * 100, 2), "%\n")
cat("Nombre de filles ciblées : ", n_target, " sur ", nrow(df_policy), "\n")

# Calcul du gain théorique
# Gain = Somme des effets des filles ciblées - Somme des effets si on traitait tout le monde ?
# Simplification : Quel est l'effet moyen sur la population CIBLÉE ?
ate_target <- mean(df_policy$cate[df_policy$should_treat == "Target"])
ate_global <- mean(df_policy$cate)

cat("Effet moyen Global (ATE) : ", round(ate_global, 4), "\n")
cat("Effet moyen sur les Ciblées (GATE) : ", round(ate_target, 4), "\n")
cat("GAIN d'efficacité par ciblage : ", round((ate_target - ate_global)/ate_global * 100, 1), "% d'amélioration relative.\n")
