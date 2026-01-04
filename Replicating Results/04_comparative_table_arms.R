library(tidyverse)
library(gt)

setwd('/home/onyxia/work/replication-buchmann-aer2023')

# 1. Chargement
df <- readRDS("data/df_analysis.rds")

# 2. Création de la variable de Groupe unique
# On doit combiner les dummies (anyoil, anyemp, oil_kk) en une seule catégorie
df_comp <- df %>%
  mutate(
    treatment_group = case_when(
      oil_kk == 1 ~ "Combined",           # Incentive + Empowerment
      anyoil == 1 & anyemp == 0 ~ "Incentive Only",
      anyemp == 1 & anyoil == 0 ~ "Empowerment Only",
      TRUE ~ "Control"                    # Ni l'un ni l'autre
    )
  )

# 3. Sélection des variables à comparer
# On prend l'Outcome (Mariage) + les Covariables de Baseline (pour le Balance Check)
vars_to_compare <- c(
  "under_18",              # Outcome principal
  "bl_age_reported",       # Age moyen
  "bl_education_mother",   # Education mère
  "bl_HHsize",             # Taille ménage
  "older_sister",          # A une grande soeur
  "bl_still_in_school"     # Scolarisée au début
)

# 4. Calcul des Moyennes par Groupe
table_data <- df_comp %>%
  select(treatment_group, all_of(vars_to_compare)) %>%
  group_by(treatment_group) %>%
  summarise(across(everything(), ~mean(.x, na.rm = TRUE))) %>%
  pivot_longer(cols = -treatment_group, names_to = "Variable", values_to = "Mean") %>%
  pivot_wider(names_from = treatment_group, values_from = Mean)

# 5. Mise en Forme Pro (gt)
# On réorganise pour mettre le Control en premier (référence)
final_table <- table_data %>%
  select(Variable, Control, `Empowerment Only`, `Incentive Only`, Combined) %>%
  mutate(
    Variable_Label = case_when(
      Variable == "under_18" ~ "Outcome: Married < 18 (%)",
      Variable == "bl_age_reported" ~ "Baseline: Age (Years)",
      Variable == "bl_education_mother" ~ "Baseline: Mother's Education (Years)",
      Variable == "bl_HHsize" ~ "Baseline: Household Size",
      Variable == "older_sister" ~ "Baseline: Has Older Sister (%)",
      Variable == "bl_still_in_school" ~ "Baseline: Still in School (%)"
    )
  ) %>%
  # On convertit les proportions (0-1) en pourcentages (0-100) pour la lisibilité
  mutate(across(c(Control, `Empowerment Only`, `Incentive Only`, Combined), 
                ~if_else(str_detect(Variable_Label, "%"), .x * 100, .x))) %>%
  select(Variable_Label, Control, `Empowerment Only`, `Incentive Only`, Combined) %>%
  # Tri des lignes : Outcome en haut, le reste en bas
  arrange(desc(str_detect(Variable_Label, "Outcome"))) %>% 
  gt() %>%
  tab_header(
    title = "Comparison Between Treatment Arms",
    subtitle = "Outcome (Unadjusted) and Baseline Balance"
  ) %>%
  fmt_number(
    columns = where(is.numeric),
    decimals = 2
  ) %>%
  # On met en gras la ligne de résultat pour que ça saute aux yeux
  tab_style(
    style = list(cell_text(weight = "bold")),
    locations = cells_body(rows = Variable_Label == "Outcome: Married < 18 (%)")
  ) %>%
  tab_source_note("Note: Means comparison. Baseline variables should be similar across groups (Randomization Balance).")

# 6. Affichage et Export
print(final_table)

# Sauvegarde HTML (Robuste)
gtsave(final_table, "output/Table_Comparatif_Bras.html")

