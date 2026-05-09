#!/usr/bin/env bash
set -euo pipefail

mkdir -p phase2-real-sts/openunison/generated

NODE_IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' sts-cluster-b-control-plane)
NODE_IP_DASH=$(echo "$NODE_IP" | tr '.' '-')

OPENUNISON_HOST="openunison.${NODE_IP_DASH}.nip.io"
DASHBOARD_HOST="dashboard.${NODE_IP_DASH}.nip.io"
API_HOST="api.${NODE_IP_DASH}.nip.io"
VAULT_STS_HOST="vault-sts.${NODE_IP_DASH}.nip.io"

cat > phase2-real-sts/openunison/generated/hosts.env <<EOF_HOSTS
NODE_IP=${NODE_IP}
OPENUNISON_HOST=${OPENUNISON_HOST}
DASHBOARD_HOST=${DASHBOARD_HOST}
API_HOST=${API_HOST}
VAULT_STS_HOST=${VAULT_STS_HOST}
EOF_HOSTS

echo "Node IP:          ${NODE_IP}"
echo "OpenUnison host:  ${OPENUNISON_HOST}"
echo "Vault STS host:   ${VAULT_STS_HOST}"

cp phase2-real-sts/openunison/openunison-headless-sts-values.template.yaml \
  phase2-real-sts/openunison/generated/openunison-headless-sts-values.yaml

sed -i.bak "s/OPENUNISON_HOST_PLACEHOLDER/${OPENUNISON_HOST}/g" phase2-real-sts/openunison/generated/openunison-headless-sts-values.yaml
sed -i.bak "s/DASHBOARD_HOST_PLACEHOLDER/${DASHBOARD_HOST}/g" phase2-real-sts/openunison/generated/openunison-headless-sts-values.yaml
sed -i.bak "s/API_HOST_PLACEHOLDER/${API_HOST}/g" phase2-real-sts/openunison/generated/openunison-headless-sts-values.yaml
sed -i.bak "s/VAULT_STS_HOST_PLACEHOLDER/${VAULT_STS_HOST}/g" phase2-real-sts/openunison/generated/openunison-headless-sts-values.yaml

kubectl create namespace openunison --dry-run=client -o yaml | kubectl apply -f -

ouctl install-auth-portal \
  -u openunison-sts-webhooks=tremolo/openunison-kube-sts-pre \
  -r openunison-sts=tremolo/openunison-kube-sts \
  phase2-real-sts/openunison/generated/openunison-headless-sts-values.yaml

cp phase2-real-sts/openunison/vault-sts-ingress.template.yaml \
  phase2-real-sts/openunison/generated/vault-sts-ingress.yaml

sed -i.bak "s/VAULT_STS_HOST_PLACEHOLDER/${VAULT_STS_HOST}/g" phase2-real-sts/openunison/generated/vault-sts-ingress.yaml

kubectl apply -f phase2-real-sts/openunison/generated/vault-sts-ingress.yaml

echo "Waiting for OpenUnison STS resources..."
for i in {1..90}; do
  if kubectl get app sts-injector-openunison-sts-vault -n openunison >/dev/null 2>&1 \
    && kubectl get app sts-token-openunison-sts-vault -n openunison >/dev/null 2>&1 \
    && kubectl get mutatingwebhookconfiguration injector-vault >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

kubectl get app sts-injector-openunison-sts-vault -n openunison >/dev/null
kubectl get app sts-token-openunison-sts-vault -n openunison >/dev/null
kubectl get mutatingwebhookconfiguration injector-vault >/dev/null

echo "Restarting OpenUnison Orchestra to load STS injector routes..."
kubectl rollout restart deployment/openunison-orchestra -n openunison
kubectl rollout status deployment/openunison-orchestra -n openunison --timeout=240s

echo "Allowing OpenUnison webhooks/routes to settle..."
sleep 30

echo
echo "OpenUnison resources:"
kubectl get pods,svc,ingress -n openunison

echo
echo "STS applications:"
kubectl get app -n openunison | grep sts || true

echo
echo "STS webhook:"
kubectl get mutatingwebhookconfiguration injector-vault
