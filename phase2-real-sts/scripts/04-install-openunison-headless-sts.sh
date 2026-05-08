#!/usr/bin/env bash
set -euo pipefail

NODE_IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' sts-cluster-b-control-plane)
NODE_IP_DASH=$(echo "$NODE_IP" | tr '.' '-')

OPENUNISON_HOST="openunison.${NODE_IP_DASH}.nip.io"
DASHBOARD_HOST="dashboard.${NODE_IP_DASH}.nip.io"
API_HOST="api.${NODE_IP_DASH}.nip.io"
VAULT_STS_HOST="vault-sts.${NODE_IP_DASH}.nip.io"

echo "Node IP:          $NODE_IP"
echo "OpenUnison host:  $OPENUNISON_HOST"
echo "Vault STS host:   $VAULT_STS_HOST"

cp phase2-real-sts/openunison/openunison-headless-sts-values.template.yaml /tmp/openunison-headless-sts-values.yaml

sed -i.bak "s/OPENUNISON_HOST_PLACEHOLDER/${OPENUNISON_HOST}/g" /tmp/openunison-headless-sts-values.yaml
sed -i.bak "s/DASHBOARD_HOST_PLACEHOLDER/${DASHBOARD_HOST}/g" /tmp/openunison-headless-sts-values.yaml
sed -i.bak "s/API_HOST_PLACEHOLDER/${API_HOST}/g" /tmp/openunison-headless-sts-values.yaml
sed -i.bak "s/VAULT_STS_HOST_PLACEHOLDER/${VAULT_STS_HOST}/g" /tmp/openunison-headless-sts-values.yaml

mkdir -p phase2-real-sts/openunison/generated
cp /tmp/openunison-headless-sts-values.yaml phase2-real-sts/openunison/generated/openunison-headless-sts-values.yaml

kubectl create namespace openunison --dry-run=client -o yaml | kubectl apply -f -

ouctl install-auth-portal \
  -u openunison-sts-webhooks=tremolo/openunison-kube-sts-pre \
  -r openunison-sts=tremolo/openunison-kube-sts \
  /tmp/openunison-headless-sts-values.yaml

echo
echo "OpenUnison resources:"
kubectl get pods,svc,ingress -n openunison
