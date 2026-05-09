#!/usr/bin/env bash
set -euo pipefail

login_and_read_secret() {
  local cluster="$1"
  local role="$2"

  echo
  echo "Testing ${cluster} with Vault role ${role}"

  local jwt
  jwt=$(curl -fsS "http://localhost:8080/mint?cluster=${cluster}&namespace=sales&saname=sales-app-sa&aud=vault" | jq -r .token)

  local login_resp
  login_resp=$(curl -fsS \
    -X POST \
    --data "$(jq -n --arg role "$role" --arg jwt "$jwt" '{role:$role,jwt:$jwt}')" \
    http://localhost:8200/v1/auth/jwt/login)

  local client_token
  client_token=$(echo "$login_resp" | jq -r .auth.client_token)

  if [[ -z "$client_token" || "$client_token" == "null" ]]; then
    echo "FAILED: no Vault client token returned"
    echo "$login_resp" | jq
    exit 1
  fi

  local secret_resp
  secret_resp=$(curl -fsS \
    -H "X-Vault-Token: $client_token" \
    http://localhost:8200/v1/secret/data/team-sales/config)

  local password
  password=$(echo "$secret_resp" | jq -r .data.data.password)

  if [[ "$password" != "existing-sales-secret" ]]; then
    echo "FAILED: secret value mismatch"
    echo "$secret_resp" | jq
    exit 1
  fi

  echo "PASS: ${cluster} authenticated and read existing Vault secret path"
}

login_and_read_secret "cluster-b" "sales-cluster-b"
login_and_read_secret "cluster-a" "sales-cluster-a"

echo
echo "SUCCESS: source and destination cluster identities can both access the same existing Vault secret path during migration."
