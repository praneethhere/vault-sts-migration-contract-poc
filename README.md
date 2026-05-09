# Vault STS Migration Contract PoC

This repository contains two related PoCs for validating Vault access during a Kubernetes platform migration.

## Phase 1: Vault JWT Contract PoC

Location:

    phase1-vault-contract/

Purpose:

    Validate the Vault-side JWT auth contract using a small local OIDC/JWKS issuer.

This proves:

    - Existing Vault secret path can remain unchanged.
    - Source and destination cluster identities can temporarily access the same Vault policy.
    - Vault bound claims can enforce cluster, namespace, and service account.
    - Wrong namespace, wrong service account, and wrong cluster are denied.

Run:

    make phase1-test

Or manually:

    cd phase1-vault-contract
    make start
    make configure
    make test

## Phase 2: Real OpenUnison STS Runtime PoC

Location:

    phase2-real-sts/

Purpose:

    Validate the real runtime flow using Kubernetes, OpenUnison/Tremolo STS, Vault JWT auth, and an existing Vault secret path.

This proves:

    Kubernetes ServiceAccount token
      -> OpenUnison/Tremolo STS exchange
      -> short-lived JWT written to /tokens/token.jwt
      -> Vault JWT auth
      -> Vault token with sales-existing policy
      -> existing Vault secret path read

Run:

    make phase2-e2e

Or manually:

    ./phase2-real-sts/scripts/90-run-real-sts-e2e.sh

## Recommended Review Path

For a quick Vault contract review, start with Phase 1.

For the full end-to-end runtime proof, run Phase 2.

## Security Note

This repo uses only sanitized sample values:

    cluster-a
    cluster-b
    kubernetes
    sales
    sales-app-sa
    existing-sales-secret

