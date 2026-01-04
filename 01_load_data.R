library(tidyverse)
library(haven) # Pour lire les .dta

setwd('/home/onyxia/work/replication-buchmann-aer2023')

# 1. Chargement
# Le script Stata ligne 76 et 139 charge la waveIII pour l'endline
df <- read_dta("data/waveIII.dta")
cat("Observations initiales :", nrow(df), "\n")

# 2. Filtrage pas à pas (selon 7_regression_tables.do)

# Ligne 142 : cap keep if bl_ever_married==0
# On ne garde que les filles non mariées au recensement initial
df <- df %>% filter(bl_ever_married == 0)
cat("Après filtre 'Non mariée Baseline' :", nrow(df), "\n")

# Ligne 146 : keep if bl_age_reported>=14 & bl_age_reported<=16
# Cible : 15-17 ans au début du programme (donc 14-16 au recensement)
df <- df %>% filter(bl_age_reported >= 14, bl_age_reported <= 16)
cat("Après filtre 'Age 14-16' :", nrow(df), "\n")

# Ligne 153 : keep if `wave'==1 (où wave correspond à endline)
# On ne garde que celles présentes dans l'enquête finale
df <- df %>% filter(endline == 1)
cat("Après filtre 'Présence Endline' :", nrow(df), "\n")

# Ligne 156-158 : keep if washedout==0
# Exclusion des villages avec problèmes techniques
df <- df %>% filter(washedout == 0)
cat("Après filtre 'Washed Out' :", nrow(df), "\n")

# Ligne 164 : drop if before_miss==1
# Exclusion de celles mariées avant le lancement officiel du programme
df <- df %>% filter(before_miss == 0)
cat("Après filtre 'Mariage pré-programme' (FINAL) :", nrow(df), "\n")

# 3. Sauvegarde
saveRDS(df, "df_analysis.rds")
