#!/usr/bin/env bash
set -euo pipefail

vlt() {
  docker exec -i \
    -e VAULT_ADDR=http://127.0.0.1:8200 \
    -e VAULT_TOKEN=root \
    vault-sts-poc vault "$@"
}

echo "Checking Vault status..."
vlt status

echo "Ensuring KV secret path exists..."
if ! vlt secrets list | grep -q '^secret/'; then
  vlt secrets enable -path=secret kv-v2
fi

echo "Writing existing migration secret..."
vlt kv put secret/team-sales/config password="existing-sales-secret"

echo "Enabling JWT auth..."
vlt auth enable jwt >/dev/null 2>&1 || true

echo "Configuring Vault JWT auth to trust local JWKS issuer..."
vlt write auth/jwt/config \
  jwks_url="http://oidc-issuer:8080/certs" \
  bound_issuer="http://oidc-issuer:8080" \
  default_role="sales-cluster-b"

echo "Writing Vault policy..."
docker exec -i \
  -e VAULT_ADDR=http://127.0.0.1:8200 \
  -e VAULT_TOKEN=root \
  vault-sts-poc vault policy write sales-existing - < vault/policies/sales-existing.hcl

echo "Writing source cluster role..."
curl -fsS \
  -H "X-Vault-Token: root" \
  -H "Content-Type: application/json" \
  --data @vault/roles/sales-cluster-a-role.json \
  http://localhost:8200/v1/auth/jwt/role/sales-cluster-a >/dev/null

echo "Writing destination cluster role..."
curl -fsS \
  -H "X-Vault-Token: root" \
  -H "Content-Type: application/json" \
  --data @vault/roles/sales-cluster-b-role.json \
  http://localhost:8200/v1/auth/jwt/role/sales-cluster-b >/dev/null

echo "Configured destination role:"
curl -fsS \
  -H "X-Vault-Token: root" \
  http://localhost:8200/v1/auth/jwt/role/sales-cluster-b | jq '.data.bound_claims, .data.token_policies, .data.ttl'
