#!/usr/bin/env bash
set -euo pipefail

helm repo add hashicorp https://helm.releases.hashicorp.com >/dev/null 2>&1 || true
helm repo update

helm upgrade --install vault hashicorp/vault \
  --namespace vault \
  --create-namespace \
  -f phase2-real-sts/vault/vault-values.yaml

kubectl wait --namespace vault \
  --for=condition=ready pod/vault-0 \
  --timeout=180s

kubectl wait --namespace vault \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=vault-agent-injector \
  --timeout=180s

kubectl get pods -n vault
kubectl exec -n vault vault-0 -- vault status
