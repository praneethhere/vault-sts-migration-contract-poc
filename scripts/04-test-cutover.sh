#!/usr/bin/env bash
set -euo pipefail

vlt() {
  docker exec -i \
    -e VAULT_ADDR=http://127.0.0.1:8200 \
    -e VAULT_TOKEN=root \
    vault-sts-poc vault "$@"
}

echo "Deleting source cluster role to simulate post-cutover cleanup..."
vlt delete auth/jwt/role/sales-cluster-a

echo "Trying old source cluster login. It should fail..."
OLD_JWT=$(curl -fsS "http://localhost:8080/mint?cluster=cluster-a&namespace=sales&saname=sales-app-sa&aud=vault" | jq -r .token)

RESP=$(curl -s \
  -X POST \
  --data "$(jq -n --arg role sales-cluster-a --arg jwt "$OLD_JWT" '{role:$role,jwt:$jwt}')" \
  http://localhost:8200/v1/auth/jwt/login)

echo "$RESP" | jq

if echo "$RESP" | jq -e '.errors[0]' >/dev/null; then
  echo "PASS: source cluster access removed after cutover."
else
  echo "FAILED: source cluster still authenticated after role deletion."
  exit 1
fi
