#!/usr/bin/env bash
set -euo pipefail

expect_denied() {
  local name="$1"
  local cluster="$2"
  local namespace="$3"
  local saname="$4"
  local expected_claim="$5"

  echo
  echo "Testing denied case: ${name}"

  local jwt
  jwt=$(curl -fsS "http://localhost:8080/mint?cluster=${cluster}&namespace=${namespace}&saname=${saname}&aud=vault" | jq -r .token)

  set +e
  local resp
  resp=$(curl -s \
    -X POST \
    --data "$(jq -n --arg role sales-cluster-b --arg jwt "$jwt" '{role:$role,jwt:$jwt}')" \
    http://localhost:8200/v1/auth/jwt/login)
  set -e

  echo "$resp" | jq

  if echo "$resp" | jq -e '.errors[0]' >/dev/null && echo "$resp" | grep -q "$expected_claim"; then
    echo "PASS: denied due to ${expected_claim} claim mismatch"
  else
    echo "FAILED: expected denial for ${expected_claim}"
    exit 1
  fi
}

expect_denied "wrong namespace" "cluster-b" "finance" "sales-app-sa" "namespace"
expect_denied "wrong service account" "cluster-b" "sales" "wrong-sa" "saname"
expect_denied "wrong cluster" "cluster-c" "sales" "sales-app-sa" "cluster"

echo
echo "SUCCESS: negative access-control tests passed."
