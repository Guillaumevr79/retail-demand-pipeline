from datetime import datetime, timedelta
from airflow.decorators import dag, task
import subprocess

@dag(
    dag_id='transformation_dbt',
    description='Transformations dbt — Silver + Gold',
    schedule=None,
    start_date=datetime(2024, 1, 1),
    catchup=False,
    default_args={'retries': 1, 'retry_delay': timedelta(minutes=5)},
    tags=['dbt', 'transformation'],
)
def transformation_dbt():

    DBT_CMD = ['/home/airflow/.local/bin/dbt']
    DBT_FLAGS = ['--profiles-dir', '/home/airflow/.dbt', '--project-dir', '/opt/dbt']

    @task
    def dbt_run_silver():
        result = subprocess.run(
            DBT_CMD + ['run', '--select', 'silver.*'] + DBT_FLAGS,
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            raise Exception(f"dbt silver failed:\nSTDOUT: {result.stdout}\nSTDERR: {result.stderr}")
        print(result.stdout)

    @task
    def dbt_run_gold():
        result = subprocess.run(
            DBT_CMD + ['run', '--select', 'gold.*'] + DBT_FLAGS,
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            raise Exception(f"dbt gold failed: {result.stderr}")
        print(result.stdout)

    @task
    def dbt_test():
        result = subprocess.run(
            DBT_CMD + ['test'] + DBT_FLAGS,
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            raise Exception(f"dbt test failed: {result.stderr}")
        print(result.stdout)

    dbt_run_silver() >> dbt_run_gold() >> dbt_test()

transformation_dbt()