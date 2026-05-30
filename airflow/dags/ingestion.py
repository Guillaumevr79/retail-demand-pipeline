from datetime import datetime, timedelta
from airflow.decorators import dag, task
from airflow.providers.airbyte.operators.airbyte import AirbyteTriggerSyncOperator
from airflow.providers.airbyte.sensors.airbyte import AirbyteJobSensor

AIRBYTE_CONN_ID = 'Airbyte'
WEATHER_CONNECTION_ID = 'ed484a44-3b4d-4cff-b015-e3923ebdf9c1'

@dag(
    dag_id='ingestion',
    description='Ingestion météo via Airbyte + M5 via script Python',
    schedule=None,
    start_date=datetime(2024, 1, 1),
    catchup=False,
    default_args={'retries': 1, 'retry_delay': timedelta(minutes=5)},
    tags=['ingestion', 'airbyte', 'm5'],
)
def ingestion():

    trigger_weather = AirbyteTriggerSyncOperator(
        task_id='trigger_weather_sync',
        airbyte_conn_id=AIRBYTE_CONN_ID,
        connection_id=WEATHER_CONNECTION_ID,
        asynchronous=True,
    )

    wait_weather = AirbyteJobSensor(
        task_id='wait_weather_sync',
        airbyte_conn_id=AIRBYTE_CONN_ID,
        airbyte_job_id=trigger_weather.output,
    )

    @task
    def ingest_m5():
        import subprocess
        result = subprocess.run(
            ['python', 'ingestion/scripts/download-m5.py'],
            cwd='/opt/airflow',
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            raise Exception(f"M5 ingestion failed: {result.stderr or result.stdout}")
        print(result.stdout)

    trigger_weather >> wait_weather >> ingest_m5()

ingestion()