#!/usr/bin/env bash
set -euo pipefail

docker rm -f vault-sts-poc oidc-issuer >/dev/null 2>&1 || true

echo "Cleaned up local PoC containers."
