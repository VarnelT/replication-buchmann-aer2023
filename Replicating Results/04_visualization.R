library(tidyverse)
library(ggplot2)
library(scales) 

setwd('/home/onyxia/work/replication-buchmann-aer2023')

# 1. Chargement
df <- readRDS("data/df_analysis.rds")

# 2. Préparation des données pour le Plot
# On calcule Moyenne + Erreur Standard (SE) pour construire l'Intervalle de Confiance à 95%
plot_data <- df %>%
  mutate(
    treatment_group = case_when(
      oil_kk == 1 ~ "Combined",
      anyoil == 1 & anyemp == 0 ~ "Incentive",     # "Incentive Only" simplifié
      anyemp == 1 & anyoil == 0 ~ "Empowerment",   # "Empowerment Only" simplifié
      TRUE ~ "Control"
    )
  ) %>%
  group_by(treatment_group) %>%
  summarise(
    mean_rate = mean(under_18, na.rm = TRUE),
    se_rate = sd(under_18, na.rm = TRUE) / sqrt(n()),
    N = n()
  ) %>%
  mutate(
    # Calcul des bornes de l'intervalle de confiance (95%)
    ci_lower = mean_rate - 1.96 * se_rate,
    ci_upper = mean_rate + 1.96 * se_rate
  )

# 3. Création du Graphique "Publication Quality"
# On définit un ordre logique : Control (ref), puis les traitements
plot_data$treatment_group <- factor(plot_data$treatment_group, 
                                    levels = c("Control", "Empowerment", "Incentive", "Combined"))

p <- ggplot(plot_data, aes(x = treatment_group, y = mean_rate, fill = treatment_group)) +
  # Barres principales
  geom_col(alpha = 0.8, width = 0.7) +
  
  # Barres d'erreur (Intervalle de confiance)
  geom_errorbar(aes(ymin = ci_lower, ymax = ci_upper), 
                width = 0.15, size = 0.8, color = "#333333") +
  
  # Ajout des étiquettes de valeur au-dessus des barres
  geom_text(aes(label = percent(mean_rate, accuracy = 0.1)), 
            vjust = -2.5, fontface = "bold", size = 4) +
  
  # Couleurs personnalisées (Palette académique)
  # Control = Gris, Incentive = Rouge/Saumon (L'effet fort), Empowerment = Bleu, Combined = Violet
  scale_fill_manual(values = c(
    "Control" = "#95a5a6",      # Gris neutre
    "Empowerment" = "#3498db",  # Bleu
    "Incentive" = "#e74c3c",    # Rouge (L'effet clé !)
    "Combined" = "#9b59b6"      # Violet
  )) +
  
  # Titres et Labels
  labs(
    title = "Impact of Interventions on Child Marriage Rates",
    subtitle = "Share of girls married before age 18 (with 95% Confidence Intervals)",
    x = "", # Pas besoin de label d'axe X car les noms sont clairs
    y = "Proportion Married < 18"
  ) +
  
  # Echelle Y en pourcentage
  scale_y_continuous(labels = percent_format(), limits = c(0, 0.35)) + # On monte à 35% pour laisser de la place au texte
  
  # Thème épuré
  theme_minimal(base_size = 14) +
  theme(
    legend.position = "none", # Pas besoin de légende, l'axe X suffit
    panel.grid.major.x = element_blank(), # Pas de lignes verticales
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold", hjust = 0),
    plot.subtitle = element_text(color = "gray40", margin = margin(b = 20)),
    axis.text.x = element_text(size = 11, face = "bold", color = "black")
  )

# 4. Affichage et Sauvegarde
print(p)

# Sauvegarde HD
ggsave("Figure1_Impact_Graph.png", plot = p, width = 8, height = 6, dpi = 300)
