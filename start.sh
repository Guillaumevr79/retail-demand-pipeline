#!/bin/bash

set -e

# 1. Initialise la base de données Airflow et crée l'utilisateur admin
docker compose up init-airflow -d

# Attend que le webserver Airflow soit healthy avant de continuer
docker compose wait airflow-webserver --condition service_healthy 2>/dev/null || sleep 10

# 2. Lance tous les services Airflow (webserver, scheduler, dag-processor) + Postgres
docker compose up -d

# Attend que le webserver soit prêt
docker compose wait webserver --condition service_healthy 2>/dev/null || sleep 15

# 3. Déploie Airbyte dans le cluster Kubernetes kind local
#    (si déjà installé, cette commande est idempotente)
abctl local install

# 4. Attend que le pod API Airbyte soit prêt avant d'ouvrir le tunnel
kubectl wait --kubeconfig ~/.airbyte/abctl/abctl.kubeconfig \
  -n airbyte-abctl pod -l airbyte=server \
  --for=condition=Ready --timeout=120s

# 5. Tue un éventuel port-forward existant sur 8001 pour éviter les conflits
pkill -f "port-forward.*8001" 2>/dev/null || true

# 6. Expose le token endpoint Airbyte sur le port 8001
kubectl port-forward --kubeconfig ~/.airbyte/abctl/abctl.kubeconfig \
  -n airbyte-abctl \
  svc/airbyte-abctl-airbyte-server-svc 8001:8001 &

PORT_FORWARD_PID=$!
echo "Port-forward Airbyte démarré (PID: $PORT_FORWARD_PID)"
echo ""
echo "Airbyte UI  : http://localhost:8000"
echo "Airflow UI  : http://localhost:8080"