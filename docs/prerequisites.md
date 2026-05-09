# Prerequisites

This repository contains two PoCs:

- Phase 1: local Vault JWT contract PoC
- Phase 2: real OpenUnison/Tremolo STS runtime PoC on kind

## Required CLI Tools

The following tools must be available locally:

    docker
    kind
    kubectl
    helm
    jq
    ouctl
    openssl
    make
    python3

On macOS, install the CLI tools using:

    brew bundle

## Docker Runtime Requirement

The docker CLI alone is not enough. A working Docker runtime must be running.

Validate with:

    docker ps

On macOS, use Docker Desktop or another Docker runtime such as Colima.

## Phase 1 Requirements

Phase 1 uses:

    Docker network
    Vault dev container
    Python OIDC/JWKS issuer container

Python packages used by the local issuer:

    Flask
    PyJWT
    cryptography

The Python dependencies are listed in:

    requirements.txt
    phase1-vault-contract/issuer/requirements.txt

Phase 1 uses these local ports:

    8080 -> local OIDC/JWKS issuer
    8200 -> local Vault dev server

Run:

    make phase1-test

## Phase 2 Requirements

Phase 2 uses:

    kind
    ingress-nginx
    Vault Helm chart
    Vault Agent Injector
    OpenUnison/Tremolo STS
    OpenUnison/Tremolo STS webhook
    Vault JWT auth

Phase 2 requires internet access to pull container images and Helm charts from:

    kindest/node
    registry.k8s.io
    hashicorp Helm repository
    tremolo Helm repository
    ghcr.io/openunison
    ghcr.io/tremolosecurity

Phase 2 uses these local ports:

    8081 -> kind ingress HTTP
    8443 -> kind ingress HTTPS
    18200 -> local Vault port-forward

Run:

    make phase2-e2e

Clean up:

    make phase2-cleanup

## Validation Commands

Check local tools:

    docker ps
    kind version
    kubectl version --client
    helm version
    jq --version
    ouctl --help
    openssl version

## Notes

This is a local PoC only.

Vault runs in dev mode.

All sample names and secrets are fake/sanitized.
