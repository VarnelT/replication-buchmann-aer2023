library(tidyverse)
library(fixest) # Le standard pour l'économétrie en R
library(glue)


# 1. Chargement des données propres
df <- readRDS("data/df_analysis.rds")

# 2. Vérification des variables de contrôle
# Le papier contrôle pour : age, household size, older sister, school enrollment, mother education, public transport.
# On vérifie si elles sont présentes (noms standards dans ce dataset)
controls_candidates <- c("older_sister", "bl_still_in_school", "bl_education_mother", 
                         "bl_HHsize", "bl_public_transit")
has_controls <- all(controls_candidates %in% names(df))

# 3. Création de la formule
# On commence par le modèle sans contrôles (juste FE) pour voir si on "touche" la cible.
# Note : 'oil_kk' est l'interaction déjà créée dans le dataset Stata
fml_base <- under_18 ~ anyoil + anyemp + oil_kk | unionID + third

if (has_controls) {
  # Si les contrôles sont là, on les ajoute (Modèle complet Table 2)
  # On ajoute aussi les dummies d'âge (bl_age_reported est souvent traité comme facteur)
  fml_full <- as.formula(
    paste("under_18 ~ anyoil + anyemp + oil_kk +", 
          paste(controls_candidates, collapse = " + "), 
          "+ i(bl_age_reported) | unionID + third")
  )
  print("✅ Variables de contrôle trouvées. On lance le modèle COMPLET.")
} else {
  fml_full <- fml_base
  print("⚠️ Variables de contrôle absentes. On lance le modèle SIMPLE (FE uniquement).")
}

# 4. Estimation (Clustering au niveau CLUSTER)
# C'est ici que la magie opère
model_did <- feols(fml_full, data = df, cluster = ~CLUSTER)

# 5. Affichage des résultats (Format Table 2)
etable(model_did, 
       fitstat = c("n", "r2"), 
       signif.code = c("***"=0.01, "**"=0.05, "*"=0.10),
       headers = "Table 2: Replication")

# 6. Comparaison avec la cible (Table 2 du papier)
cat("\n--- VERDICT (CIBLES PAPIER) ---\n")
cat("Incentive (anyoil) : Cible -0.049***\n")
cat("Empowerment (anyemp) : Cible -0.007\n")
cat("Interaction (oil_kk) : Cible 0.019\n")