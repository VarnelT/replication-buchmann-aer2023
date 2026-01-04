library(tidyverse)
library(haven) # Pour lire les .dta

setwd('/home/onyxia/work/replication-buchmann-aer2023')

# -----------------------------------------------------------------------------
# PROJECT: Replication - A Signal to End Child Marriage (Buchmann et al. 2023)
# SCRIPT: 01_data_cleaning.R
# OBJECTIF: Créer l'échantillon d'analyse final (N ~ 15,576)
# SOURCE: Basé sur '7_regression_tables.do' (lignes 142-167)
# -----------------------------------------------------------------------------

library(tidyverse)
library(haven)   # Pour lire les .dta
library(glue)    # Pour les messages dynamiques

# --- 1. CONFIGURATION & CHARGEMENT ---

# Chemin vers les données brutes (Ajuste selon ton dossier local)
# Le papier utilise Wave III (Parents) pour l'analyse principale 
input_path  <- "data/waveIII.dta"
output_path <- "data/df_analysis.rds"

if (!file.exists(input_path)) {
  stop(glue("ERREUR CRITIQUE: Le fichier {input_path} est introuvable."))
}

print(glue("Chargement de : {input_path}"))
df_raw <- read_dta(input_path)

print(glue("Observations brutes : {nrow(df_raw)}"))

# --- 2. FILTRAGE (REPLICATION STRICTE DU DO-FILE) ---

df_analysis <- df_raw %>%
  # A. Filtre: Jamais mariée à la baseline
  # Stata: keep if bl_ever_married==0
  filter(bl_ever_married == 0) %>%

  # B. Filtre: Âge cible (15-17 au programme = 14-16 au recensement)
  # Stata: keep if bl_age_reported>=14 & bl_age_reported<=16
  filter(bl_age_reported >= 14, bl_age_reported <= 16) %>%

  # C. Filtre: Présence à l'Endline (Wave 3)
  # Stata: keep if `wave'==1 (où wave correspond à endline)
  filter(endline == 1) %>%

  # D. Filtre: Exclure les villages 'Washed Out' (problèmes techniques)
  # Stata: keep if washedout==0
  filter(washedout == 0) %>%

  # E. Filtre: Exclure celles mariées avant le début du programme
  # Stata: drop if before_miss==1
  filter(before_miss == 0)

# --- 3. VALIDATION (LE "MAGIC NUMBER") ---

n_final <- nrow(df_analysis)
target_n <- 15576 # Chiffre cité page 14 du papier 

print("---------------------------------------------------")
print(glue("Nombre d'observations final : {n_final}"))
print(glue("Cible du papier (Table 1/2) : {target_n}"))
print("---------------------------------------------------")

if (abs(n_final - target_n) < 50) {
  print("✅ SUCCÈS : Réplication de l'échantillon réussie !")
} else {
  print("⚠️ ATTENTION : Écart suspect. Vérifie les filtres.")
}

# --- 4. NETTOYAGE DES VARIABLES CLES ---

# On garde et on renomme proprement les variables pour la suite
df_clean <- df_analysis %>%
  select(
    # Identifiants
    girl_id = girlID,
    cluster_id = CLUSTER,
    union_id = unionID,
    
    # Outcomes (Résultats)
    married_under_18 = under_18,
    married_under_16 = under_16,
    marriage_age = marriage_age,
    
    # Traitements (Dummies)
    treat_incentive = anyoil,    # "Incentive" dans le papier
    treat_empowerment = anyemp,  # "Empowerment" dans le papier
    treat_interaction = oil_kk,  # Interaction terme
    
    # Covariates (Contrôles de base)
    age_reported = bl_age_reported
    # On ajoutera les autres contrôles (éducation mère, richesse) à l'étape suivante
  )

# --- 5. SAUVEGARDE ---
saveRDS(df_clean, output_path)
print(glue("Fichier nettoyé sauvegardé sous : {output_path}"))