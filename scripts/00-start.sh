#!/usr/bin/env bash
set -euo pipefail

docker network inspect stsnet >/dev/null 2>&1 || docker network create stsnet

docker rm -f vault-sts-poc oidc-issuer >/dev/null 2>&1 || true

docker run -d \
  --name vault-sts-poc \
  --network stsnet \
  -p 8200:8200 \
  --entrypoint vault \
  -e VAULT_DEV_ROOT_TOKEN_ID=root \
  -e VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:8200 \
  hashicorp/vault:latest \
  server -dev -dev-no-store-token >/dev/null

docker run -d \
  --name oidc-issuer \
  --network stsnet \
  -p 8080:8080 \
  -v "$PWD/issuer":/app:ro \
  -w /app \
  -e ISSUER=http://oidc-issuer:8080 \
  -e TOKEN_TTL_SECONDS=900 \
  python:3.11-slim \
  sh -c "pip install -q -r requirements.txt && python issuer.py" >/dev/null

echo "Waiting for services..."
sleep 10

docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo
echo "Checking OIDC issuer:"
curl -fsS http://localhost:8080/.well-known/openid-configuration | jq

echo
echo "Checking Vault health:"
curl -fsS http://localhost:8200/v1/sys/health | jq
