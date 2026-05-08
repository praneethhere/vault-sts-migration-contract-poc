# Phase 2: Real OpenUnison STS Runtime PoC

This phase extends the local Vault JWT contract PoC into a Kubernetes runtime PoC.

## Goal

Validate the full runtime flow:

    Kubernetes Pod ServiceAccount token
      -> OpenUnison/Tremolo STS TokenReview validation
      -> short-lived Vault-scoped JWT
      -> Vault JWT auth
      -> Vault Agent Injector
      -> existing Vault secret path

## Current checkpoint

The following base components are working:

    kind cluster
    ingress-nginx
    Vault server in dev mode
    Vault Agent Injector
    baseline Vault secret
    baseline Vault policy

## Current validated Vault path

    secret/data/team-sales/config

## Current validated policy

    path "secret/data/team-sales/*" {
      capabilities = ["read"]
    }

## Why this phase matters

Phase 1 simulated the STS-issued JWT and proved that Vault can authorize access using JWT claims such as cluster, namespace, and service account.

Phase 2 is intended to prove the full runtime path using a real Kubernetes ServiceAccount token, real OpenUnison/Tremolo STS validation, real short-lived JWT issuance, and Vault Agent integration.

## Current status

Completed:

    1. Created kind cluster with ingress port mapping.
    2. Installed ingress-nginx.
    3. Installed Vault server in dev mode.
    4. Installed Vault Agent Injector.
    5. Created baseline Vault secret.
    6. Created baseline Vault policy.

Next:

    1. Install OpenUnison/Tremolo STS.
    2. Configure Vault JWT auth to trust the real STS issuer.
    3. Deploy a test pod with STS and Vault Agent annotations.
    4. Validate positive and negative access-control scenarios.

## Scripts

Create the kind cluster:

    ./phase2-real-sts/scripts/00-create-kind.sh

Install ingress-nginx:

    ./phase2-real-sts/scripts/01-install-ingress.sh

Install Vault and Vault Agent Injector:

    ./phase2-real-sts/scripts/02-install-vault.sh

Configure the baseline Vault secret and policy:

    ./phase2-real-sts/scripts/03-configure-vault-baseline.sh

## Notes

Vault is running in dev mode only for this local PoC.

Do not use this Vault configuration for production.
