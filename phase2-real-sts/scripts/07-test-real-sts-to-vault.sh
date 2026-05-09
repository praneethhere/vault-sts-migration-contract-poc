#!/usr/bin/env bash
set -euo pipefail

kubectl exec -n sales sts-mutation-test -c app -- cat /tokens/token.jwt > /tmp/real-sts-token.jwt

echo "Decoded real STS token claims:"
python3 <<'PY_DEC'
import base64
import json

token = open("/tmp/real-sts-token.jwt").read().strip()
parts = token.split(".")

def decode(part):
    part += "=" * (-len(part) % 4)
    return json.loads(base64.urlsafe_b64decode(part))

print(json.dumps(decode(parts[1]), indent=2))
PY_DEC

REAL_STS_JWT=$(cat /tmp/real-sts-token.jwt)

LOGIN_RESP=$(curl -fsS \
  -X POST \
  --data "$(jq -n --arg role sales-real-sts --arg jwt "$REAL_STS_JWT" '{role:$role,jwt:$jwt}')" \
  http://localhost:18200/v1/auth/jwt/login)

echo "Vault login response:"
echo "$LOGIN_RESP" | jq

CLIENT_TOKEN=$(echo "$LOGIN_RESP" | jq -r .auth.client_token)

if [ -z "$CLIENT_TOKEN" ] || [ "$CLIENT_TOKEN" = "null" ]; then
  echo "FAILED: Vault did not return a client token."
  exit 1
fi

SECRET_RESP=$(curl -fsS \
  -H "X-Vault-Token: $CLIENT_TOKEN" \
  http://localhost:18200/v1/secret/data/team-sales/config)

echo "Secret read response:"
echo "$SECRET_RESP" | jq

PASSWORD=$(echo "$SECRET_RESP" | jq -r .data.data.password)

if [ "$PASSWORD" != "existing-sales-secret" ]; then
  echo "FAILED: expected existing-sales-secret, got $PASSWORD"
  exit 1
fi

echo
echo "SUCCESS: Real Kubernetes SA token -> OpenUnison STS JWT -> Vault JWT auth -> existing secret path read."
