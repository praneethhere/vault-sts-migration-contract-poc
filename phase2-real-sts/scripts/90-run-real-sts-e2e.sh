#!/usr/bin/env bash
set -euo pipefail

./phase2-real-sts/scripts/00-create-kind.sh
./phase2-real-sts/scripts/01-install-ingress.sh
./phase2-real-sts/scripts/02-install-vault.sh
./phase2-real-sts/scripts/03-configure-vault-baseline.sh
./phase2-real-sts/scripts/04-install-openunison-sts.sh
./phase2-real-sts/scripts/05-create-sales-test-pod.sh
./phase2-real-sts/scripts/06-configure-vault-real-sts.sh
./phase2-real-sts/scripts/07-test-real-sts-to-vault.sh
./phase2-real-sts/scripts/08-test-negative-real-sts.sh
