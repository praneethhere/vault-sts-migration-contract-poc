#!/usr/bin/env bash
set -euo pipefail

echo "Running negative STS authorization tests..."

kubectl create namespace finance --dry-run=client -o yaml | kubectl apply -f -
kubectl create serviceaccount sales-app-sa -n finance --dry-run=client -o yaml | kubectl apply -f -
kubectl create serviceaccount wrong-sa -n sales --dry-run=client -o yaml | kubectl apply -f -

kubectl create configmap ouca \
  -n finance \
  --from-file=ca.crt=/tmp/ouca.crt \
  --dry-run=client -o yaml | kubectl apply -f -

create_and_wait_for_injection() {
  local ns="$1"
  local pod="$2"
  local manifest="$3"

  local injected="false"

  for attempt in 1 2 3; do
    echo "Creating ${ns}/${pod}, injection attempt ${attempt}..."

    kubectl delete pod "$pod" -n "$ns" --ignore-not-found --wait=true
    kubectl apply -f "$manifest"

    sleep 20

    init_containers=$(kubectl get pod "$pod" -n "$ns" -o jsonpath='{.spec.initContainers[*].name}' 2>/dev/null || true)

    if echo "$init_containers" | grep -q "sts-creds-sidecar"; then
      injected="true"
      break
    fi

    sleep 20
  done

  if [ "$injected" != "true" ]; then
    echo "FAILED: sts-creds-sidecar was not injected for ${ns}/${pod}"
    kubectl get pod "$pod" -n "$ns" -o yaml || true
    exit 1
  fi
}

create_and_wait_for_injection "finance" "sts-negative-namespace-test" "phase2-real-sts/apps/negative-wrong-namespace-pod.yaml"
create_and_wait_for_injection "sales" "sts-negative-sa-test" "phase2-real-sts/apps/negative-wrong-serviceaccount-pod.yaml"

sleep 45

echo
echo "Wrong namespace sidecar logs:"
NS_LOGS=$(kubectl logs -n finance sts-negative-namespace-test -c sts-creds-sidecar --tail=80 || true)
echo "$NS_LOGS"

echo
echo "Wrong service account sidecar logs:"
SA_LOGS=$(kubectl logs -n sales sts-negative-sa-test -c sts-creds-sidecar --tail=80 || true)
echo "$SA_LOGS"

if echo "$NS_LOGS" | grep -q "unexpected status 403" && echo "$SA_LOGS" | grep -q "unexpected status 403"; then
  echo
  echo "SUCCESS: Negative STS authorization tests denied wrong namespace and wrong service account."
else
  echo
  echo "FAILED: Expected 403 denial in both negative tests."
  exit 1
fi
