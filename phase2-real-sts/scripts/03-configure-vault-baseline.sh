#!/usr/bin/env bash
set -euo pipefail

kubectl exec -n vault vault-0 -- sh -c \
  'VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN=root vault kv put secret/team-sales/config password="existing-sales-secret"'

kubectl exec -i -n vault vault-0 -- sh -c \
  'VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN=root vault policy write sales-existing -' <<'POLICY'
path "secret/data/team-sales/*" {
  capabilities = ["read"]
}
POLICY

echo "Baseline Vault secret and policy configured."
