#!/usr/bin/env bash
set -euo pipefail

mkdir -p phase2-real-sts/openunison/generated

kubectl get secret vault-sts-keypair -n openunison \
  -o jsonpath='{.data.tls\.crt}' | base64 -d > /tmp/vault-sts.crt

openssl x509 -in /tmp/vault-sts.crt -pubkey -noout > /tmp/vault-sts-pub.pem

pkill -f "kubectl port-forward -n vault svc/vault 18200:8200" >/dev/null 2>&1 || true

kubectl port-forward -n vault svc/vault 18200:8200 \
  > phase2-real-sts/openunison/generated/vault-port-forward.log 2>&1 &

echo $! > phase2-real-sts/openunison/generated/vault-port-forward.pid

sleep 3

curl -fsS http://localhost:18200/v1/sys/health | jq

curl -s \
  -H "X-Vault-Token: root" \
  -H "Content-Type: application/json" \
  --data '{"type":"jwt"}' \
  http://localhost:18200/v1/sys/auth/jwt >/dev/null || true

python3 <<'PY_CFG'
import json
from pathlib import Path

pub = Path("/tmp/vault-sts-pub.pem").read_text()

payload = {
    "jwt_validation_pubkeys": [pub],
    "bound_issuer": "https://vault-sts." + Path("phase2-real-sts/openunison/generated/hosts.env").read_text().split("NODE_IP=")[1].splitlines()[0].replace(".", "-") + ".nip.io",
    "default_role": "sales-real-sts"
}

Path("/tmp/vault-jwt-config.json").write_text(json.dumps(payload))
print(json.dumps(payload, indent=2))
PY_CFG

curl -fsS \
  -H "X-Vault-Token: root" \
  -H "Content-Type: application/json" \
  --data @/tmp/vault-jwt-config.json \
  http://localhost:18200/v1/auth/jwt/config | jq

curl -fsS \
  -H "X-Vault-Token: root" \
  -H "Content-Type: application/json" \
  --data @phase2-real-sts/vault/sales-real-sts-role.json \
  http://localhost:18200/v1/auth/jwt/role/sales-real-sts | jq

echo "Vault JWT auth configured for real OpenUnison STS."
