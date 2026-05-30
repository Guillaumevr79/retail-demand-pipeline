# Retail Demand Forecasting Pipeline — GCP

![Python](https://img.shields.io/badge/Python-3.11-blue?logo=python)
![dbt](https://img.shields.io/badge/dbt-1.11-orange?logo=dbt)
![Airflow](https://img.shields.io/badge/Airflow-3.2-017CEE?logo=apacheairflow)
![GCP](https://img.shields.io/badge/GCP-BigQuery%20%7C%20GCS-4285F4?logo=googlecloud)
![Terraform](https://img.shields.io/badge/Terraform-1.x-7B42BC?logo=terraform)
![Airbyte](https://img.shields.io/badge/Airbyte-latest-615EFF?logo=airbyte)

---

## Contexte / Context

### Français

Pipeline ELT end-to-end pour la prédiction de demande retail, basé sur le dataset M5 Forecasting (Walmart, 42 000 séries temporelles journalières, 2011–2016) enrichi de données météo historiques pour trois états américains (Californie, Texas, Wisconsin).

L'objectif est de modéliser la demande à l'article et au magasin, d'entraîner un modèle de prévision ARIMA_PLUS via BigQuery ML et d'exposer les prédictions sur 28 jours dans un dashboard Looker Studio.

### English

End-to-end ELT pipeline for retail demand forecasting, built on the M5 Forecasting dataset (Walmart, 42,000 daily time series, 2011–2016) enriched with historical weather data for three US states (California, Texas, Wisconsin).

The goal is to model demand at the item × store level, train an ARIMA_PLUS forecast model via BigQuery ML, and expose 28-day predictions in a Looker Studio dashboard.

---

## Architecture

```text
┌─────────────────────┐    ┌──────────────────────┐
│  Open-Meteo API     │    │  M5 Kaggle dataset   │
│  (CA, TX, WI)       │    │  (ventes + prix +    │
│                     │    │   calendrier)         │
└────────┬────────────┘    └──────────┬───────────┘
         │ Airbyte                    │ Python script
         │ (connecteur custom)        │ download-m5.py
         ▼                            ▼
┌─────────────────────────────────────────────────┐
│             GCS — Bronze Layer                   │
│  gs://retail-demand-pl-bronze/                   │
│  ├── m5/bronze/           (CSV — 3 fichiers)     │
│  └── weather/bronze/      (JSONL — 3 états)      │
└──────────────────────┬──────────────────────────┘
                       │ dbt run-operation
                       │ stage_external_sources
                       ▼
┌─────────────────────────────────────────────────┐
│       BigQuery — External Tables (Bronze)        │
│  retail_demand_pl_dataset                        │
│  ├── m5_sales_ext (UNPIVOT 1913 colonnes)        │
│  ├── m5_calendar_ext                             │
│  ├── m5_sell_prices_ext                          │
│  ├── weather_california_ext                      │
│  ├── weather_texas_ext                           │
│  └── weather_wisconsin_ext                       │
└──────────────────────┬──────────────────────────┘
                       │ dbt run
                       ▼
┌─────────────────────────────────────────────────┐
│          BigQuery — Silver Layer (views)         │
│  ├── stg_m5_sales      (UNPIVOT + typage)        │
│  ├── stg_m5_calendar   (normalisation dates)     │
│  ├── stg_m5_sell_prices                          │
│  └── stg_weather       (UNNEST JSON Airbyte)     │
└──────────────────────┬──────────────────────────┘
                       │ dbt run
                       ▼
┌─────────────────────────────────────────────────┐
│           BigQuery — Gold Layer (tables)         │
│  ├── fct_daily_sales     (join ventes + météo)   │
│  └── fct_demand_features (lags, rolling avg,     │
│                            SNAP, événements)     │
└──────────────────────┬──────────────────────────┘
                       │ BigQuery ML
                       ▼
┌─────────────────────────────────────────────────┐
│         BigQuery ML — ARIMA_PLUS                 │
│  m5_forecast_model                               │
│  ├── 42k séries (item_id × store_id)             │
│  ├── horizon = 28 jours                          │
│  └── auto_arima + decompose_time_series          │
└──────────────────────┬──────────────────────────┘
                       │ Looker Studio
                       ▼
              Dashboard (4 pages)
```

### Architecture Medallion

| Couche | Stockage | Rôle |
| ------ | -------- | ---- |
| **Bronze** | GCS + BigQuery External Tables | Données brutes telles que reçues, sans transformation |
| **Silver** | BigQuery Views | Nettoyage, typage, normalisation, UNPIVOT/UNNEST |
| **Gold** | BigQuery Tables | Modèles analytiques et features ML prêts à l'emploi |

---

## Stack technique / Tech stack

| Composant | Technologie | Détail |
| --------- | ----------- | ------ |
| Ingestion météo | Airbyte (connecteur custom Open-Meteo) | 3 streams JSONL → GCS |
| Ingestion M5 | Python 3.11 + Kaggle API | ZIP → CSV → GCS |
| Stockage brut | Google Cloud Storage | Bucket `retail-demand-pl-bronze` |
| Transformation | dbt Core 1.11 + dbt-bigquery | External tables, UNPIVOT 1913 cols, UNNEST JSON, features ML |
| Entrepôt | BigQuery | Dataset `retail_demand_pl_dataset` (EU) |
| Orchestration | Apache Airflow 3.2 (Docker) | TaskFlow API, 3 DAGs |
| Machine Learning | BigQuery ML ARIMA_PLUS | 42k séries, horizon 28 j, confidence 90% |
| Infrastructure | Terraform | GCS bucket, BigQuery dataset, Service Account, IAM |
| Visualisation | Looker Studio | 4 pages, connecté directement à BigQuery |

---

## Structure du repo / Repository structure

```text
retail-demand-pipeline/
│
├── terraform/                    # Infrastructure GCP
│   ├── main.tf                   # GCS bucket, BigQuery dataset, SA, IAM
│   ├── variables.tf
│   └── outputs.tf
│
├── ingestion/
│   └── scripts/
│       └── download-m5.py        # Téléchargement Kaggle + upload GCS
│
├── dbt/
│   └── retail_demand_pl/
│       ├── dbt_project.yml       # Config : silver=view, gold=table
│       ├── packages.yml          # dbt_external_tables 0.11.1
│       ├── macros/
│       │   └── unpivot_sales.sql # UNPIVOT dynamique 1913 colonnes
│       └── models/
│           ├── bronze/
│           │   └── sources.yml   # External tables → GCS
│           ├── silver/
│           │   ├── stg_m5_sales.sql
│           │   ├── stg_m5_calendar.sql
│           │   ├── stg_m5_sell_prices.sql
│           │   └── stg_weather.sql
│           └── gold/
│               ├── fct_daily_sales.sql
│               └── fct_demand_features.sql
│
├── bigquery_ml/
│   ├── models/
│   │   └── train_forecast_model.sql    # CREATE OR REPLACE MODEL ARIMA_PLUS
│   └── predictions/
│       └── generate_predictions.sql    # ml.forecast(horizon=28)
│
├── airflow/
│   ├── Dockerfile                # Base airflow:3.2.1 + airbyte + kaggle + dbt-bigquery
│   └── dags/
│       ├── ingestion.py          # Airbyte sync + ingest_m5
│       ├── transformation_dbt.py # dbt silver → gold → test
│       └── forecasting_ml.py     # BigQuery ML train + predict
│
├── docker-compose.yml            # Airflow (webserver, scheduler, dag-processor, postgres)
├── start.sh                      # Démarrage complet (Docker + Airbyte + port-forward)
└── stop.sh                       # Arrêt propre
```

---

## How to run

### Prérequis / Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) en cours d'exécution
- [gcloud CLI](https://cloud.google.com/sdk/docs/install) configuré
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.0
- [Python 3.11](https://www.python.org/) + `pip install dbt-bigquery kaggle google-cloud-storage`
- [abctl](https://github.com/airbytehq/abctl) (Airbyte local)
- Compte Kaggle avec règles M5 acceptées sur [kaggle.com/competitions/m5-forecasting-accuracy](https://www.kaggle.com/competitions/m5-forecasting-accuracy/rules)
- Fichier clé service account GCP dans `~/.gcp/retail-sa-key.json`

---

### Étape 1 — Infrastructure Terraform

```bash
cd terraform/
terraform init
terraform plan
terraform apply
```

Crée : bucket GCS `retail-demand-pl-bronze`, dataset BigQuery `retail_demand_pl_dataset`, service account `retail-sa` avec les rôles IAM nécessaires.

---

### Étape 2 — Ingestion des données

**Météo (Airbyte) :**

```bash
abctl local install    # déploie Airbyte dans Kubernetes local (~30 min première fois)
abctl local credentials  # récupérer client-id et client-secret
```

Créer le connecteur custom Open-Meteo et la destination GCS dans l'UI Airbyte (`http://localhost:8000`), puis lancer le sync.

**M5 (script Python) :**

```bash
pip install kaggle google-cloud-storage
python ingestion/scripts/download-m5.py
```

---

### Étape 3 — Transformations dbt

```bash
cd dbt/retail_demand_pl/
dbt deps                                  # installe dbt_external_tables
dbt debug                                 # vérifie la connexion BigQuery
dbt run-operation stage_external_sources  # crée les external tables dans BigQuery
dbt run                                   # silver (views) + gold (tables)
dbt test                                  # tests qualité données
```

---

### Étape 4 — BigQuery ML

Lancer les deux requêtes depuis la console BigQuery ou via le DAG Airflow :

```sql
-- 1. Entraînement (~10-20 min pour 42k séries)
-- bigquery_ml/models/train_forecast_model.sql

-- 2. Génération des prédictions sur 28 jours
-- bigquery_ml/predictions/generate_predictions.sql
```

---

### Étape 5 — Orchestration Airflow

```bash
./start.sh   # démarre Docker Compose + Airbyte + port-forward kubectl 8001
```

Accéder à l'UI Airflow sur `http://localhost:8080`.

Créer les connexions Airflow (une seule fois) :

```bash
# Connexion Google Cloud pour BigQueryInsertJobOperator
docker compose exec dag-processor python -m airflow connections add google_cloud_default \
  --conn-type google_cloud_platform \
  --conn-extra '{"key_path": "/home/airflow/.gcp/retail-sa-key.json", "project": "retail-demand-pipeline"}'
```

Lancer les DAGs dans l'ordre :

| DAG | Description |
| --- | ----------- |
| `ingestion` | Sync météo Airbyte + téléchargement M5 |
| `transformation_dbt` | dbt silver → gold → tests |
| `forecasting_ml` | Entraînement ARIMA_PLUS + prédictions |

---

## Dashboard Looker Studio

[Ouvrir le dashboard](https://datastudio.google.com/reporting/d2958072-8e71-47a0-9a1a-445f13de0f0a)

| Page | Contenu |
| ---- | ------- |
| Vue globale | KPIs agrégés : ventes totales, séries actives, tendance sur la période |
| Analyse produits | Performances par article, département et magasin |
| Impact météo | Corrélation température / précipitations avec les ventes par état |
| Tendances & features ML | Lags, moyennes mobiles, prédictions ARIMA_PLUS sur 28 jours |

---

## Résultats / Results

- 42 000 séries temporelles item × store modélisées sur 1913 jours (2011–2016)
- Prédictions de ventes sur 28 jours avec intervalles de confiance à 90% via ARIMA_PLUS
- Pipeline orchestré automatiquement via Airflow : ingestion → transformation → prédiction
- Enrichissement météo pour 3 états (CA, TX, WI) via connecteur Airbyte custom

---

## Notes

- Les credentials (`~/.gcp/retail-sa-key.json`, `~/.dbt/profiles.yml`, `.env`) ne sont jamais versionnés.
- Toujours démarrer via `./start.sh` (relance le port-forward Airbyte 8001 nécessaire aux DAGs).
- Les connexions Airflow créées via CLI sont perdues au `docker compose down` si elles ne sont pas définies en variable d'environnement `AIRFLOW_CONN_*` dans `docker-compose.yml`.
- Modifier un DAG est immédiatement pris en compte (volume-monté). Modifier le `Dockerfile` nécessite un rebuild : `docker compose build --no-cache webserver scheduler dag-processor`.
