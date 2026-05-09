# Phase 1: Vault JWT Contract PoC

This phase validates the Vault-side JWT auth contract using a small local OIDC/JWKS issuer.

## What This Phase Proves

This phase proves:

    cluster-a / sales / sales-app-sa -> can access existing Vault path
    cluster-b / sales / sales-app-sa -> can access existing Vault path

    wrong namespace      -> denied
    wrong serviceAccount -> denied
    wrong cluster        -> denied

The existing Vault secret path remains unchanged:

    secret/data/team-sales/config

No Vault secrets are copied or moved.

## What This Phase Does Not Prove

This phase does not deploy the real OpenUnison/Tremolo STS runtime.

It simulates the STS-issued JWT locally to validate the Vault contract:

    JWT signature validation
    JWT audience validation
    JWT bound claim validation
    Vault policy mapping
    source/destination cluster dual-run
    negative access-control cases

For the real runtime flow, see:

    ../phase2-real-sts/

## Run

From this folder:

    make start
    make configure
    make test

Clean up:

    make cleanup

## Expected Result

The final output should show:

    PASS: cluster-b authenticated and read existing Vault secret path
    PASS: cluster-a authenticated and read existing Vault secret path
    PASS: denied due to namespace claim mismatch
    PASS: denied due to saname claim mismatch
    PASS: denied due to cluster claim mismatch
    SUCCESS: negative access-control tests passed.
