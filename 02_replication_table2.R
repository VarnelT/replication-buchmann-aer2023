library(tidyverse)
library(fixest) # Le standard pour l'économétrie en R
library(glue)
library(haven)
library(gt) 
install.packages("gt")
setwd('/home/onyxia/work/replication-buchmann-aer2023')


# 1. Chargement des données propres
df <- readRDS("data/df_analysis.rds")


#--------------------------------------------------------------------------------
       ### TABLE1 / SUMMARY STATISTICS ###
#---------------------------------------------------------------------------------

# --- 1. PREPARATION DES VARIABLES ---
# Conversion explicite en numérique pour éviter les conflits de types
df_ready <- df %>%
  transmute(
    is_age_15 = (bl_age_reported == 14),
    
    age_endline = as.numeric(el_age_predicted),
    ever_married = as.numeric(ever_married) * 100,
    married_under_18 = as.numeric(under_18) * 100,
    married_under_16 = as.numeric(under_16) * 100,
    ever_birth = as.numeric(ever_birth) * 100,
    birth_under_20 = as.numeric(ever_birth_20) * 100,
    
    # Dot : conditionnelle au mariage (sinon NA)
    dowry = if_else(as.numeric(ever_married) == 100, as.numeric(dowry), NA_real_),
    
    arranged_marriage = as.numeric(arranged_marriage) * 100,
    age_gap = as.numeric(age_gap),
    husband_outside = as.numeric(outside_village) * 100,
    still_in_school = as.numeric(still_in_school) * 100,
    last_class_passed = as.numeric(education),
    currently_working = as.numeric(iga_yesno) * 100
  )
# --- 2. CALCUL DES STATISTIQUES ---

# Fonction robuste avec séparateur unique '___'
calc_stats <- function(data) {
  data %>%
    summarise(across(everything(), list(
      mean = ~mean(.x, na.rm = TRUE),
      sd = ~sd(.x, na.rm = TRUE)
    ), .names = "{.col}___{.fn}")) %>% 
    pivot_longer(everything(), names_to = c("variable", "stat"), names_sep = "___") %>%
    pivot_wider(names_from = stat, values_from = value)
}

# Calculs
stats_all <- calc_stats(select(df_ready, -is_age_15))
n_all <- nrow(df_ready)

stats_15 <- calc_stats(df_ready %>% filter(is_age_15) %>% select(-is_age_15))
n_15 <- sum(df_ready$is_age_15)

# Fusion
final_tab <- left_join(stats_all, stats_15, by = "variable", suffix = c("_all", "_15"))


# --- 4. MISE EN FORME ET ORDONNANCEMENT ---

# Définition de l'ordre exact des lignes souhaité
target_order <- c(
  "age_endline", "ever_married", "married_under_18", 
  "married_under_16", "ever_birth", "birth_under_20", 
  "dowry", "arranged_marriage", "age_gap", 
  "husband_outside", "still_in_school", 
  "last_class_passed", "currently_working"
)

# On applique l'ordre et les libellés AVANT de passer à gt()
final_tab_ordered <- final_tab %>%
  mutate(variable = factor(variable, levels = target_order)) %>%
  arrange(variable) %>% # C'est ici que la magie opère sans erreur
  mutate(Label = case_when(
    variable == "age_endline" ~ "Age at Endline",
    variable == "ever_married" ~ "Ever married (%)",
    variable == "married_under_18" ~ "Married < 18 (%)",
    variable == "married_under_16" ~ "Married < 16 (%)",
    variable == "ever_birth" ~ "Ever birth (%)",
    variable == "birth_under_20" ~ "Birth < 20 (%)",
    variable == "dowry" ~ "Dowry (USD, conditional on married)",
    variable == "arranged_marriage" ~ "Arranged marriage (%)",
    variable == "age_gap" ~ "Age gap (Husband-Wife)",
    variable == "husband_outside" ~ "Husband from outside village (%)",
    variable == "still_in_school" ~ "Still in school (%)",
    variable == "last_class_passed" ~ "Last class passed",
    variable == "currently_working" ~ "Currently working (%)",
    TRUE ~ as.character(variable)
  ))

# --- 5. RENDU GT ---
table_output <- final_tab_ordered %>%
  select(Label, mean_all, sd_all, mean_15, sd_15) %>%
  gt() %>%
  tab_header(title = "Table 1: Sample summary statistics") %>%
  tab_spanner(label = paste0("Girls age 15-17 (N=", n_all, ")"), columns = c(mean_all, sd_all)) %>%
  tab_spanner(label = paste0("Girls age 15 (N=", n_15, ")"), columns = c(mean_15, sd_15)) %>%
  cols_label(mean_all = "Mean", sd_all = "S.D.", mean_15 = "Mean", sd_15 = "S.D.") %>%
  fmt_number(columns = where(is.numeric), decimals = 1) %>%
  # Correction ici : on utilise le numéro de ligne ou une condition plus simple si besoin
  fmt_number(rows = (Label == "Dowry (USD, conditional on married)"), columns = everything(), decimals = 1) %>%
  tab_source_note("Replication of Buchmann et al. (2023)")

# Affichage
print(table_output)
gtsave(table_output, "Table1_SummaryStatistics_Replication.png")













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