
setwd('/home/onyxia/work/replication-buchmann-aer2023')


library(tidyverse)
library(ggplot2)

# 1. Récupération des prédictions (CATE)
cates <- predict(forest)$predictions

# 2. Intégration dans le dataframe pour plotting
df_plot <- df_ml %>%
  mutate(cate = cates) %>%
  mutate(
    # On reprend l'éducation de la mère pour voir si visuellement il y a une tendance
    mom_edu_cat = case_when(
      bl_education_mother == 0 ~ "0. Aucune éducation",
      bl_education_mother > 0 & bl_education_mother <= 5 ~ "1. Primaire",
      bl_education_mother > 5 ~ "2. Secondaire+"
    )
  )

# 3. Le Graphique de "Non-Hétérogénéité"
# On va montrer que les distributions se chevauchent parfaitement
ggplot(df_plot, aes(x = cate, fill = mom_edu_cat)) +
  geom_density(alpha = 0.4) +
  geom_vline(xintercept = average_treatment_effect(forest)["estimate"], 
             linetype = "dashed", color = "black", linewidth=1) +
  labs(
    title = "Distribution des Effets du Traitement (CATE)",
    subtitle = "Résultat : L'effet est homogène (les courbes se superposent)",
    x = "Effet estimé sur la probabilité de mariage précoce",
    y = "Densité",
    fill = "Éducation Mère"
  ) +
  theme_minimal() +
  scale_fill_brewer(palette = "Set1")

# Sauvegarde pour ton rapport/Github
ggsave("cate_distribution.png", width = 8, height = 5)
