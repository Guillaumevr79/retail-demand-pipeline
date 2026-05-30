#!/bin/bash

# 1. Tue le port-forward Airbyte
pkill -f "port-forward.*8001" 2>/dev/null || true
echo "Port-forward Airbyte arrêté"

# 2. Arrête les services Airflow et Postgres
docker compose down
echo "Services Airflow arrêtés"