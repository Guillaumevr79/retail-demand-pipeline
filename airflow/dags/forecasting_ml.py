from datetime import datetime, timedelta
from airflow.decorators import dag
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator

PROJECT_ID = 'retail-demand-pipeline'
LOCATION = 'EU'

@dag(
    dag_id='forecasting_ml',
    description='Training + prédictions BigQuery ML ARIMA_PLUS',
    schedule=None,
    start_date=datetime(2024, 1, 1),
    catchup=False,
    default_args={'retries': 1, 'retry_delay': timedelta(minutes=5)},
    tags=['bigquery_ml', 'forecasting'],
)
def forecasting_ml():

    train_model = BigQueryInsertJobOperator(
        task_id='train_bqml_model',
        configuration={
            'query': {
                'query': open('/opt/airflow/bigquery_ml/models/train_forecast_model.sql').read(),
                'useLegacySql': False,
            }
        },
        project_id=PROJECT_ID,
        location=LOCATION,
    )

    generate_predictions = BigQueryInsertJobOperator(
        task_id='generate_predictions',
        configuration={
            'query': {
                'query': open('/opt/airflow/bigquery_ml/predictions/generate_predictions.sql').read(),
                'useLegacySql': False,
            }
        },
        project_id=PROJECT_ID,
        location=LOCATION,
    )

    train_model >> generate_predictions

forecasting_ml()