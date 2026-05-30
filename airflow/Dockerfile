FROM apache/airflow:3.2.1

USER airflow
RUN pip install --no-cache-dir \
        apache-airflow-providers-airbyte==5.4.1 \
        kaggle \
        dbt-bigquery

RUN sed -i \
    -e 's/self\.client\.post(token_url, data=payload)/self.client.post(token_url, json=payload)/' \
    -e 's/if response_data\.get("token_type") != "Bearer":/if False and response_data.get("token_type") != "Bearer":/' \
    /home/airflow/.local/lib/python3.13/site-packages/airbyte_api/_hooks/clientcredentials.py

USER root