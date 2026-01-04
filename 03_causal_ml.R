library(tidyverse)
library(grf)      # Le package de Susan Athey
library(fixest)   # Juste pour model.matrix si besoin
install.packages("grf")


# 1. Chargement des données propres
df <- readRDS("data/df_analysis.rds")

# --- DATA PREPARATION POUR LE ML ---
# Le ML a besoin de X (Caractéristiques), Y (Outcome), W (Traitement)

# Sélection des Covariates (X) pour l'hétérogénéité
# On prend tout ce qui pourrait modérer l'effet (Richesse, Age, Education, Géographie)
vars_heterogeneity <- c(
  "bl_age_reported",      # Age (numérique)
  "bl_HHsize",            # Taille ménage
  "bl_education_mother",  # Education mère
  "bl_still_in_school",   # En école au début ? (0/1)
  "bl_public_transit",    # Accès transport (proxy isolement)
  "older_sister"          # A une grande sœur
)

# On nettoie les NAs pour le ML (grf n'aime pas les trous)
df_ml <- df %>%
  select(under_18, anyoil, CLUSTER, all_of(vars_heterogeneity)) %>%
  na.omit()

cat("Observations pour le ML : ", nrow(df_ml), "\n")

# Création des Matrices (Format requis par grf)
# 1. On force Y et W à être de simples vecteurs numériques (On enlève les labels Stata)
Y <- as.numeric(df_ml$under_18)
W <- as.numeric(df_ml$anyoil)

# 2. Pour X, on s'assure aussi que c'est une matrice purement numérique
X <- df_ml %>% 
  select(all_of(vars_heterogeneity)) %>% 
  mutate(across(everything(), as.numeric)) %>% # Conversion de sécurité
  as.matrix()

# 3. Idem pour les clusters
cluster_ids <- as.numeric(factor(df_ml$CLUSTER))
# --- 2. ENTRAINEMENT DE LA CAUSAL FOREST ---
# C'est ici que ça calcule. Ça peut prendre 1-2 minutes.
cat("\n--- Entraînement de la Causal Forest (2000 arbres) ---\n")
set.seed(123) # Pour la reproductibilité

forest <- causal_forest(
  X = X,
  Y = Y,
  W = W,
  clusters = cluster_ids, # TRES IMPORTANT : Respecter le design expérimental
  num.trees = 2000,       # Assez pour stabiliser les résultats
  honesty = TRUE          # Sépare l'échantillon pour éviter l'overfitting (Standard Athey)
)

# --- 3. RÉSULTATS & ANALYSE ---

# A. L'Effet Moyen (Average Treatment Effect)
# Doit être proche de ton résultat OLS (-0.048)
ate_result <- average_treatment_effect(forest)
cat("\n--- ATE estimé par la Forêt ---\n")
print(ate_result)
cat("Rappel OLS : -0.048\n")

# B. Le Test d'Hétérogénéité (Calibration Test)
# C'est LE test à mettre dans ton papier.
# "Mean.forest.prediction" : Est-ce que le modèle prédit bien l'effet moyen ? (Doit être significatif)
# "Differential.forest.prediction" : Y a-t-il de l'hétérogénéité significative ? (Si p-value < 0.05, BINGO !)
cat("\n--- Test de Calibration (Best Linear Projection) ---\n")
test_calibration(forest)

# C. Importance des Variables
# Quelles caractéristiques drivent l'hétérogénéité ?
var_imp <- variable_importance(forest)
rownames(var_imp) <- colnames(X)
cat("\n--- Variable Importance (Top Drivers) ---\n")
print(var_imp[order(var_imp, decreasing = TRUE), , drop = FALSE])

# D. Visualisation simple (Distribution des CATE)
# Si on voit une cloche étalée, il y a de l'hétérogénéité.
# Si c'est un pic unique, l'effet est constant.
cates <- predict(forest)$predictions
hist(cates, main = "Distribution des Effets du Traitement (CATE)",
     xlab = "Effet estimé (Gain en probabilité de non-mariage)",
     breaks = 30, col = "skyblue")
abline(v = ate_result["estimate"], col = "red", lwd = 2, lty = 2)
legend("topright", legend = "ATE Moyen", col = "red", lty = 2)
