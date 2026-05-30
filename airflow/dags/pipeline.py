from datetime import datetime, timedelta
from airflow.decorators import dag
from airflow.operators.trigger_dagrun import TriggerDagRunOperator

@dag(
    dag_id='pipeline',
    description='Pipeline complet — Ingestion → Transformation → Forecasting',
    schedule='@weekly',
    start_date=datetime(2024, 1, 1),
    catchup=False,
    default_args={'retries': 1, 'retry_delay': timedelta(minutes=5)},
    tags=['pipeline', 'orchestration'],
)
def pipeline():

    trigger_ingestion = TriggerDagRunOperator(
        task_id='trigger_ingestion',
        trigger_dag_id='ingestion',
        wait_for_completion=True,
    )

    trigger_transformation = TriggerDagRunOperator(
        task_id='trigger_transformation',
        trigger_dag_id='transformation_dbt',
        wait_for_completion=True,
    )

    trigger_forecasting = TriggerDagRunOperator(
        task_id='trigger_forecasting',
        trigger_dag_id='forecasting_ml',
        wait_for_completion=True,
    )

    trigger_ingestion >> trigger_transformation >> trigger_forecasting

pipeline()