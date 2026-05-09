# Phase 2: Real OpenUnison STS Runtime PoC

This phase validates the full runtime path using Kubernetes, OpenUnison/Tremolo STS, Vault JWT auth, and an existing Vault secret path.

## What This Phase Proves

This phase proves the real end-to-end flow:

    Kubernetes ServiceAccount token
      -> OpenUnison/Tremolo STS exchange
      -> short-lived JWT written to /tokens/token.jwt
      -> Vault JWT auth
      -> Vault token with sales-existing policy
      -> existing Vault secret path read

## Current Test Identity

    namespace: sales
    serviceAccount: sales-app-sa
    cluster claim: kubernetes
    audience: http://vault.vault.svc:8200

## Existing Vault Secret Path

    secret/data/team-sales/config

The secret is not copied or moved.

## Positive Scenario

The pod `sales/sts-mutation-test` uses the service account `sales-app-sa`.

Expected result:

    1. OpenUnison mutating webhook injects sts-creds-sidecar.
    2. Sidecar exchanges the real Kubernetes service-account token.
    3. A real short-lived STS JWT is written to /tokens/token.jwt.
    4. Vault accepts the STS JWT through JWT auth.
    5. Vault returns a token with sales-existing policy.
    6. The existing Vault secret path is readable.

## Negative Scenarios

The following should be denied by OpenUnison STS authorization:

    finance / sales-app-sa
    sales / wrong-sa

Expected result:

    OpenUnison STS returns HTTP 403 and no valid token is generated.

## One-Command Run

From the repository root:

    ./phase2-real-sts/scripts/90-run-real-sts-e2e.sh

## Manual Run

Create kind cluster:

    ./phase2-real-sts/scripts/00-create-kind.sh

Install ingress-nginx:

    ./phase2-real-sts/scripts/01-install-ingress.sh

Install Vault and Vault Agent Injector:

    ./phase2-real-sts/scripts/02-install-vault.sh

Configure baseline Vault secret and policy:

    ./phase2-real-sts/scripts/03-configure-vault-baseline.sh

Install OpenUnison/Tremolo STS:

    ./phase2-real-sts/scripts/04-install-openunison-sts.sh

Create the positive test pod:

    ./phase2-real-sts/scripts/05-create-sales-test-pod.sh

Configure Vault JWT auth for the real STS signer:

    ./phase2-real-sts/scripts/06-configure-vault-real-sts.sh

Validate real STS token login to Vault:

    ./phase2-real-sts/scripts/07-test-real-sts-to-vault.sh

Run negative tests:

    ./phase2-real-sts/scripts/08-test-negative-real-sts.sh

Clean up:

    ./phase2-real-sts/scripts/99-cleanup-real-sts.sh

## Notes

This is a local PoC only.

Vault runs in dev mode.

The OpenUnison STS issuer host is generated dynamically using the kind node IP and nip.io.

Generated local files are written under:

    phase2-real-sts/openunison/generated/

Those files are ignored by git.
