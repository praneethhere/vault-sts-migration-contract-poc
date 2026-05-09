#!/usr/bin/env bash
set -euo pipefail

if [ -f phase2-real-sts/openunison/generated/vault-port-forward.pid ]; then
  kill "$(cat phase2-real-sts/openunison/generated/vault-port-forward.pid)" >/dev/null 2>&1 || true
fi

pkill -f "kubectl port-forward -n vault svc/vault 18200:8200" >/dev/null 2>&1 || true

kind delete cluster --name sts-cluster-b || true

rm -rf phase2-real-sts/openunison/generated

echo "Cleaned up Phase 2 real STS local environment."
