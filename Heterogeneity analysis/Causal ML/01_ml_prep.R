library(tidyverse)
library(caret) # Pour le one-hot encoding si besoin (ou model.matrix)

# --- 1. CHARGEMENT ET FILTRAGE ---
# On charge le dataset propre complet
df <- readRDS("data/df_analysis.rds")

cat("Nombre initial d'observations : ", nrow(df), "\n")

# CRÉPON STEP B : "Construire un sous-échantillon pour la comparaison incitation vs contrôle"
# On garde uniquement :
# - Control (anyoil == 0 ET anyemp == 0 ET oil_kk == 0)
# - Incentive Only (anyoil == 1 ET anyemp == 0)
# Donc on exclut tout ce qui touche à l'Empowerment (anyemp == 1 ou oil_kk == 1)

df_ml <- df %>%
  filter(anyemp == 0 & oil_kk == 0)

cat("Nombre d'observations après filtrage (Incentive vs Control) : ", nrow(df_ml), "\n")
cat("Répartition du traitement :\n")
print(table(df_ml$anyoil)) # 0 = Control, 1 = Incentive

# --- 2. DÉFINITION DES VECTEURS CIBLES (Y et W) ---

# Y = Outcome (Mariage avant 18 ans)
Y <- df_ml$under_18

# W = Treatment (Incitation)
W <- df_ml$anyoil

# --- 3. PRÉPARATION DE LA MATRICE DES COVARIABLES (X) ---
# On sélectionne les variables susceptibles de créer de l'hétérogénéité.
# Règle d'or : Uniquement des variables 'baseline' (bl_...) ou invariantes (religion, lieu).

covariates_list <- c(
  "bl_age_reported",      # L'âge est souvent le facteur #1
  "bl_education_mother",  # Education maternel
  "bl_HHsize",            # Pauvreté / Structure familiale
  "older_sister",         # Pression matrimoniale (Marier l'aînée d'abord)
  "bl_still_in_school",   # Statut scolaire initial
  "bl_public_transit",    # Accès / Isolement géographique
  "bl_mother_schooled"    # Dummy si mère scolarisée
)

# Création du sous-tableau X
X_raw <- df_ml %>%
  select(all_of(covariates_list))

# --- 4. GESTION DES VALEURS MANQUANTES (NA) ---
# Les Forêts Aléatoires gèrent parfois les NA, mais pour être propre et compatible
# avec tous les algos (Lasso, R-Learner), on fait une imputation simple par la moyenne.

X_imputed <- X_raw %>%
  mutate(across(everything(), ~ifelse(is.na(.), mean(., na.rm = TRUE), .)))

# Transformation en MATRICE (Format obligatoire pour 'grf' et 'glmnet')
X_matrix <- as.matrix(X_imputed)

# --- 5. SAUVEGARDE POUR L'ETAPE SUIVANTE ---
# On sauvegarde tout dans une liste propre
ml_data <- list(
  Y = Y,
  W = W,
  X = X_matrix,
  df_raw = df_ml # On garde le df original pour retrouver les ID plus tard si besoin
)

saveRDS(ml_data, "data/ml_data_stepB.rds")

cat("\n✅ Données ML prêtes et sauvegardées dans 'data/ml_data_stepB.rds'.\n")
cat("Dimensions de X : ", dim(X_matrix)[1], " lignes x ", dim(X_matrix)[2], " colonnes.\n")

