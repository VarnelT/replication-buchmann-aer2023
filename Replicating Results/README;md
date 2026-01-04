# Étape A : Réplication des Résultats Expérimentaux

Ce dossier contient l'ensemble des scripts et résultats liés à la **première étape** de la roadmap : la reproduction exacte des résultats principaux de l'article de Buchmann et al. (2023).

L'objectif est de valider la construction de l'échantillon et la robustesse des estimateurs avant d'étendre l'analyse (Étape B).

## 📊 Résultat Principal (Validation)

Nous avons réussi à reproduire à l'identique l'effet de l'incitation financière sur le mariage précoce (Table 2 de l'article original).

| Métrique | Article Original (Stata) | Notre Réplication (R) | Conclusion |
| :--- | :--- | :--- | :--- |
| **Effet Incitation (Incentive)** | **-0.049** (4.9 pp) | **-0.049** | ✅ Succès |
| **Erreur Standard (SE)** | (0.010) | (0.010) | ✅ Succès |
| **Taille Échantillon** | N = 15,576 | N = 15,576 | ✅ Succès |

> **Interprétation :** L'incitation financière réduit la probabilité de mariage avant 18 ans de près de 5 points de pourcentage par rapport au groupe de contrôle.

## 📂 Structure du Dossier

L'analyse est séquentielle et organisée comme suit :

### 1. Préparation des Données
* **`01_load_data.R`** :
    * Chargement des données brutes (`waveIII.dta`).
    * Nettoyage et filtrage pour reconstruire l'échantillon analytique strict ($N=15,576$).
    * Création des variables indicatrices de traitement.

### 2. Analyse Économétrique
* **`02_replicating_table.R`** :
    * Estimation des modèles de probabilité linéaire (LPM) avec effets fixes.
    * Utilisation du package `fixest` pour gérer les effets fixes de haute dimension (Union + Tercile) et le clustering (Village).
    * Production de la **Table 2** (Impact principal).

* **`03_Comparing_bras.R`** :
    * Génération des statistiques descriptives et du test d'équilibre (Balance Check).
    * Comparaison des moyennes "naïves" entre les bras (Control, Incentive, Empowerment).
    * Production de la **Table 1** (Preuve de la randomisation).

### 3. Visualisation
* **`04_Vizualising.R`** :
    * Production des graphiques illustratifs pour le rapport.
    * Génération du graphique des intervalles de confiance comparant les groupes de traitement.

### 4. Sorties (Outputs)
* 📁 **`table/`** : Contient les tableaux de résultats exportés au format HTML/PNG pour intégration dans le rapport final.
* 📊 **Graphique** : Visualisation de l'impact (`.png` ou interactif).

## 🛠️ Méthodologie Technique

* **Langage :** R
* **Approche :** Réplication stricte des spécifications économétriques.
* **Standard Errors :** Clusterisés au niveau du village (161 clusters), robustes à l'hétéroscédasticité.
* **Contrôles :** Âge, éducation de la mère, taille du ménage, présence d'une grande sœur.

---
*Note : Ce module valide les fondations nécessaires pour l'analyse d'hétérogénéité (Causal ML) menée dans l'Étape B.*