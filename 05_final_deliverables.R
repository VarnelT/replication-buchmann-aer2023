library(tidyverse)
library(ggplot2)
library(fixest)
library(grf)

setwd('/home/onyxia/work/replication-buchmann-aer2023')

# Chargement
df <- readRDS("data/df_analysis.rds")

# --- STEP A : GRAPHIQUE ILLUSTRATIF (Correction noms variables) ---
# Mapping : anyoil = Incentive, anyemp = Empowerment, oil_kk = Interaction
plot_data <- df %>%
  mutate(group = case_when(
    anyoil == 1 & anyemp == 0 ~ "Incentive Only",
    anyemp == 1 & anyoil == 0 ~ "Empowerment Only",
    oil_kk == 1 ~ "Combined",
    TRUE ~ "Control"
  )) %>%
  group_by(group) %>%
  summarise(
    mean_marriage = mean(under_18, na.rm = TRUE),  # Variable outcome: under_18
    se = sd(under_18, na.rm = TRUE) / sqrt(n())
  )

# Le Plot
ggplot(plot_data, aes(x = reorder(group, mean_marriage), y = mean_marriage, fill = group)) +
  geom_col(alpha = 0.8, width = 0.7) +
  geom_errorbar(aes(ymin = mean_marriage - 1.96*se, ymax = mean_marriage + 1.96*se), width = 0.2) +
  labs(
    title = "Impact des Interventions sur le Mariage Précoce",
    subtitle = "Réplication Étape A : L'incitation (Incentive) réduit significativement le taux",
    y = "Proportion mariée < 18 ans",
    x = ""
  ) +
  theme_minimal() +
  scale_y_continuous(labels = scales::percent) +
  theme(legend.position = "none")

# Sauvegarde
ggsave("stepA_graphique_illustratif.png", width = 8, height = 5)


# ----------- STEP B : POLICY VALUE FUNCTION -----------------------------------

# Si 'forest' n'est plus en mémoire, il faudrait relancer le bloc d'entraînement du script 03.
# On suppose ici qu'il est actif.

# 1. Prédictions (CATE)
cates <- predict(forest)$predictions

# 2. Règle de décision
df_policy <- df_ml %>% 
  mutate(
    cate = cates,
    # On cible si l'effet est négatif (baisse du mariage)
    should_treat = if_else(cate < 0, 1, 0),
    actual_treat = anyoil  # Nom original Stata
  )

# 3. Tableau des Sous-groupes (Demandé par Crépon)
table_targeting <- df_policy %>%
  group_by(should_treat) %>%
  summarise(
    N = n(),
    Avg_CATE = mean(cate),
    Avg_Mom_Edu = mean(bl_education_mother), # Education mère
    Avg_HH_Size = mean(bl_HHsize)            # Taille ménage
  )

print("--- TABLEAU CIBLAGE (STEP B) ---")
print(table_targeting)

# 4. Conclusion Policy
prop_to_treat <- mean(df_policy$should_treat)
cat("\nPourcentage de filles à cibler selon le modèle : ", round(prop_to_treat * 100, 1), "%\n")
