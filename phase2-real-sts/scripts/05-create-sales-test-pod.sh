#!/usr/bin/env bash
set -euo pipefail

kubectl create namespace sales --dry-run=client -o yaml | kubectl apply -f -
kubectl create serviceaccount sales-app-sa -n sales --dry-run=client -o yaml | kubectl apply -f -

kubectl get secret ou-tls-certificate -n openunison \
  -o jsonpath='{.data.tls\.crt}' | base64 -d > /tmp/ouca.crt

kubectl create configmap ouca \
  -n sales \
  --from-file=ca.crt=/tmp/ouca.crt \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Creating positive STS test pod and waiting for sidecar injection..."

INJECTED="false"

for attempt in 1 2 3; do
  echo "Injection attempt ${attempt}..."

  kubectl delete pod sts-mutation-test -n sales --ignore-not-found --wait=true
  kubectl apply -f phase2-real-sts/apps/sales-test-pod.yaml

  sleep 20

  INIT_CONTAINERS=$(kubectl get pod sts-mutation-test -n sales -o jsonpath='{.spec.initContainers[*].name}' 2>/dev/null || true)

  if echo "$INIT_CONTAINERS" | grep -q "sts-creds-sidecar"; then
    INJECTED="true"
    break
  fi

  echo "STS sidecar not injected yet. Waiting before retry..."
  sleep 20
done

if [ "$INJECTED" != "true" ]; then
  echo "FAILED: sts-creds-sidecar was not injected."
  echo
  echo "Pod containers:"
  kubectl get pod sts-mutation-test -n sales -o jsonpath='containers: {.spec.containers[*].name}{"\n"}initContainers: {.spec.initContainers[*].name}{"\n"}' || true
  echo
  echo "Webhook:"
  kubectl get mutatingwebhookconfiguration injector-vault -o yaml | sed -n '1,120p' || true
  exit 1
fi

kubectl wait pod/sts-mutation-test -n sales --for=condition=ready --timeout=180s

kubectl get pod sts-mutation-test -n sales
kubectl get pod sts-mutation-test -n sales -o jsonpath='containers: {.spec.containers[*].name}{"\n"}initContainers: {.spec.initContainers[*].name}{"\n"}'

kubectl logs -n sales sts-mutation-test -c sts-creds-sidecar --tail=80

kubectl exec -n sales sts-mutation-test -c app -- sh -c 'ls -la /tokens; cat /tokens/token.jwt | cut -c1-120'
