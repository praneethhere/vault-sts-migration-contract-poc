#!/usr/bin/env bash
set -euo pipefail

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.13.0/deploy/static/provider/kind/deploy.yaml

echo "Waiting for ingress-nginx deployment to exist..."
for i in {1..30}; do
  if kubectl get deployment ingress-nginx-controller -n ingress-nginx >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

kubectl rollout status deployment/ingress-nginx-controller \
  -n ingress-nginx \
  --timeout=180s

kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s

kubectl get pods -n ingress-nginx
