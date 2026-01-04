library(tidyverse)
library(grf) # Le package star pour les Forêts Causales
library(ggplot2)

# --- 1. CHARGEMENT DES DONNÉES PRÉPARÉES ---
data_ml <- readRDS("data/ml_data_stepB.rds")

# Extraction brute
Y_raw <- as.numeric(data_ml$Y)  # Conversion en vecteur numérique
W_raw <- as.numeric(data_ml$W)
X_raw <- data_ml$X
df_raw <- data_ml$df_raw

# DÉTECTION ET SUPPRESSION DES NAs (Le Fix)
# On garde uniquement les lignes où Y et W ne sont pas NA
valid_obs <- complete.cases(Y_raw, W_raw)

# On filtre tout le monde (Y, W, X et le dataframe de référence)
Y <- Y_raw[valid_obs]
W <- W_raw[valid_obs]
X <- X_raw[valid_obs, ]
df_clean <- df_raw[valid_obs, ]
cat("Entraînement de la Causal Forest sur N =", length(Y), "observations...\n")

# --- 2. ENTRAÎNEMENT DU MODÈLE (CAUSAL FOREST) ---
# num.trees : 3000 est un standard pour être stable
# seed : Pour que le résultat soit reproductible (important !)
forest <- causal_forest(
  X = X,
  Y = Y,
  W = W,
  num.trees = 3000,
  seed =  123
)

cat("✅ Modèle entraîné avec succès !\n")

# --- 3. PRÉDICTION DES CATE ---
predictions <- predict(forest)
cates <- predictions$predictions

# On ajoute les prédictions au dataframe PROPRE (df_clean)
# C'est important d'utiliser df_clean pour que les dimensions collent
df_results <- df_clean %>%
  mutate(cate = cates)

# --- 4. ANALYSE ATE ---
ate_result <- average_treatment_effect(forest, target.sample = "all")
cat("\n--- RÉSULTATS GLOBAUX ---\n")
cat("ATE estimé par la forêt :", round(ate_result["estimate"], 4), 
    "(SE:", round(ate_result["std.err"], 4), ")\n")

# --- 5. VISUALISATION ---
p <- ggplot(df_results, aes(x = cate)) +
  geom_histogram(bins = 30, fill = "#3498db", color = "white", alpha = 0.8) +
  geom_vline(xintercept = ate_result["estimate"], linetype = "dashed", color = "red", size = 1) +
  geom_vline(xintercept = 0, color = "black", size = 0.8) +
  labs(
    title = "Distribution des Effets de Traitement Individuels (CATE)",
    subtitle = paste0("ATE = ", round(ate_result["estimate"], 3)),
    x = "CATE (Effet sur le mariage)",
    y = "Fréquence"
  ) +
  theme_minimal()

print(p)
ggsave("Heterogeneity analysis/Causal ML/Causal ML/cate_distribution.png", width = 8, height = 5)

# --- 6. SAUVEGARDE ---
saveRDS(forest, "data/causal_forest_model.rds")
saveRDS(df_results, "data/df_cate_results.rds")

cat("\n✅ Terminé. Graphique sauvegardé.\n")