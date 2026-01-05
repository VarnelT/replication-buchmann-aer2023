library(tidyverse)
library(fixest) 
library(glue)
library(modelsummary) 
library(haven)
library(gt) 




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
gtsave(table_output, "Replicating Results/Tables/Table1_SummaryStatistics_Replication.html")



#--------------------------------------------------------------------------------
       ### TABLE2 / MARRIAGE OUTCOMES ###
#---------------------------------------------------------------------------------

# --- DÉFINITION DES VARIABLES ---
# Outcome : under_18 (Mariée avant 18 ans)
# Traitements : anyoil (Incentive), anyemp (Empowerment), oil_kk (Interaction)
# Fixed Effects : unionID (Strate admin) + third (Tercile de taille village)
# Cluster : CLUSTER (Village)

# Contrôles (Liste exacte du papier) :
# - older_sister (A une grande soeur non mariée)
# - bl_still_in_school (Scolarisée à la baseline)
# - bl_education_mother (Education de la mère)
# - bl_HHsize (Taille du ménage)
# - bl_public_transit (Accès transport public)
# - bl_age_reported (Age dummies pour contrôler l'âge exact)

# --- 3. ESTIMATION ---

# Modèle 1 : Échantillon Complet (15-17 ans)
model_1 <- feols(under_18 ~ anyemp + anyoil + oil_kk + 
                   older_sister + bl_still_in_school + bl_education_mother + 
                   bl_HHsize + bl_public_transit + i(bl_age_reported) | 
                   unionID + third, 
                 cluster = ~CLUSTER,
                 data = df)

# Modèle 2 : Sous-échantillon (Age 15)
# Note: bl_age_reported = 14 correspond à 15 ans au début du programme
df_15 <- df %>% filter(bl_age_reported == 14)
model_2 <- feols(under_18 ~ anyemp + anyoil + oil_kk + 
                   older_sister + bl_still_in_school + bl_education_mother + 
                   bl_HHsize + bl_public_transit | 
                   unionID + third, 
                 cluster = ~CLUSTER,
                 data = df_15)

# --- 3. CALCUL DE LA "CONTROL MEAN" ---
# Le papier affiche la moyenne du groupe de contrôle en bas du tableau.
# On doit la calculer manuellement pour l'ajouter.

# Moyenne Control pour Col 1
mean_ctrl_1 <- df %>% 
  filter(anyoil == 0 & anyemp == 0 & oil_kk == 0) %>% # Groupe Control pur
  summarise(m = mean(under_18, na.rm=TRUE)) %>% pull()

# Moyenne Control pour Col 2 (Age 15)
mean_ctrl_2 <- df_15 %>% 
  filter(anyoil == 0 & anyemp == 0 & oil_kk == 0) %>% 
  summarise(m = mean(under_18, na.rm=TRUE)) %>% pull()

# On crée un petit dataframe pour injecter ces lignes
rows <- data.frame(
  term = c("Control Mean", "FE: Union"),
  "Col1" = c(sprintf("%.3f", mean_ctrl_1), "Yes"), # Format 3 décimales
  "Col2" = c(sprintf("%.3f", mean_ctrl_2), "Yes")
)

# --- 4. CONFIGURATION DU TABLEAU ---

# Dictionnaire pour renommer les variables comme dans l'article
coef_map <- c(
  "anyemp" = "Empowerment",
  "anyoil" = "Incentive",
  "oil_kk" = "Incen.*Empow."
)

# Création du tableau avec modelsummary
table_gt <- modelsummary(
  list("Age 15-17" = model_1, "Age 15" = model_2),
  coef_map = coef_map,
  stars = c('*' = .1, '**' = .05, '***' = .01),
  gof_map = c("nobs", "r.squared"), # On garde N et R2
  add_rows = rows, # On ajoute notre ligne Control Mean
  output = "gt" # On veut un objet gt pour le styliser après
) %>%
  # --- 5. STYLISATION GT (COSMÉTIQUE) ---
  tab_header(
    title = "Table 2: Marriage outcomes, women unmarried at program start"
  ) %>%
  tab_spanner(
    label = "Married < 18",
    columns = c("Age 15-17", "Age 15")
  ) %>%
  # Mise en forme des chiffres (3 décimales pour coefs et SE)
  fmt_number(
    columns = 2:3,
    decimals = 3
  ) %>%
  # Ajout des parenthèses autour des Standard Errors (classique en éco)
  # modelsummary le fait souvent par défaut, mais on s'assure du look
  tab_style(
    style = cell_text(align = "center"),
    locations = cells_body()
  ) %>%
  tab_source_note("Notes: Standard errors clustered at the village level in parentheses. Replication of Buchmann et al. (2023).")

# --- 6. EXPORTATION ROBUSTE ---

# Affichage console
print(table_gt)

# Sauvegarde HTML (Sécurité)
gtsave(table_gt, "Replicating Results/Tables/Table2_Replication.html")
