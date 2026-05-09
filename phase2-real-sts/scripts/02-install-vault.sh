#!/usr/bin/env bash
set -euo pipefail

helm repo add hashicorp https://helm.releases.hashicorp.com >/dev/null 2>&1 || true
helm repo update

helm upgrade --install vault hashicorp/vault \
  --namespace vault \
  --create-namespace \
  -f phase2-real-sts/vault/vault-values.yaml

echo "Waiting for vault-0 pod to be created..."
for i in {1..90}; do
  if kubectl get pod vault-0 -n vault >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

if ! kubectl get pod vault-0 -n vault >/dev/null 2>&1; then
  echo "FAILED: vault-0 pod was not created."
  kubectl get all -n vault || true
  helm get values vault -n vault || true
  exit 1
fi

echo "Waiting for vault-0 to be Ready..."
kubectl wait --namespace vault \
  --for=condition=ready pod/vault-0 \
  --timeout=300s

echo "Waiting for Vault Agent Injector deployment..."
for i in {1..90}; do
  if kubectl get deployment vault-agent-injector -n vault >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

if ! kubectl get deployment vault-agent-injector -n vault >/dev/null 2>&1; then
  echo "FAILED: Vault Agent Injector deployment was not created."
  kubectl get all -n vault || true
  exit 1
fi

kubectl wait --namespace vault \
  --for=condition=available deployment/vault-agent-injector \
  --timeout=240s

kubectl get pods -n vault
kubectl exec -n vault vault-0 -- vault status
