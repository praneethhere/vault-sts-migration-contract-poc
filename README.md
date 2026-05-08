# Vault STS Migration Contract PoC

This repository demonstrates a local proof-of-concept for validating the Vault-side contract required for a Kubernetes namespace migration from a source cluster to a destination cluster.

The goal is to prove that a migrated namespace can continue using the existing Vault secret path without copying or moving secrets.

## Problem Being Tested

During a Kubernetes platform migration, an application namespace may move from one Kubernetes cluster to another.

Example:

```text
Before migration:
  cluster-a / namespace sales / serviceAccount sales-app-sa

After migration:
  cluster-b / namespace sales / serviceAccount sales-app-sa
```

The main question is:

```text
Can Vault safely allow both source and destination cluster identities to access the same existing Vault secret path during the migration window?
```

This PoC validates that answer.

## What This PoC Proves

This PoC proves:

```text
cluster-a / sales / sales-app-sa -> can access existing Vault path
cluster-b / sales / sales-app-sa -> can access existing Vault path

wrong namespace      -> denied
wrong serviceAccount -> denied
wrong cluster        -> denied
```

The existing Vault secret path remains unchanged:

```text
secret/data/team-sales/config
```

No Vault secrets are copied or moved.

## What This PoC Does Not Prove

This is not a full OpenUnison/Tremolo STS deployment.

This PoC simulates the STS-issued JWT locally using a small Python OIDC/JWKS issuer. It validates the Vault-side authorization contract:

```text
JWT signature validation
JWT audience validation
JWT bound claim validation
Vault policy mapping
source/destination cluster dual-run
negative access-control cases
```

The next lab step is to deploy the real Tremolo/OpenUnison STS and validate:

```text
Pod ServiceAccount token
  -> OpenUnison STS TokenReview
  -> short-lived Vault-scoped JWT
  -> Vault JWT auth
  -> Vault token
  -> existing secret path
```

## Why This Matters

The migration should not depend on copying Vault secrets from one cluster-specific path to another.

Instead, Vault should continue to own the secret path and policy, while the migration process temporarily authorizes both the source and destination Kubernetes workload identities.

That gives a safer migration model:

```text
1. Add destination cluster identity.
2. Run source and destination in parallel.
3. Validate application access.
4. Cut over traffic.
5. Remove source cluster identity.
```

## Architecture

```text
                +-----------------------+
                |  Fake local STS/OIDC  |
                |  issuer.py            |
                |                       |
                |  Issues JWT with:     |
                |  - cluster            |
                |  - namespace          |
                |  - saname             |
                |  - audience           |
                +----------+------------+
                           |
                           | signed JWT + JWKS
                           v
+--------------------------+--------------------------+
|                       Vault                         |
|                                                        |
|  auth/jwt/config trusts issuer JWKS                  |
|                                                        |
|  role sales-cluster-a:                               |
|    bound_claims: cluster-a, sales, sales-app-sa      |
|    policy: sales-existing                            |
|                                                        |
|  role sales-cluster-b:                               |
|    bound_claims: cluster-b, sales, sales-app-sa      |
|    policy: sales-existing                            |
|                                                        |
|  policy sales-existing:                              |
|    read secret/data/team-sales/*                     |
+------------------------------------------------------+
```

## Repository Layout

```text
.
├── issuer/
│   ├── issuer.py
│   └── requirements.txt
├── vault/
│   ├── policies/
│   │   └── sales-existing.hcl
│   └── roles/
│       ├── sales-cluster-a-role.json
│       └── sales-cluster-b-role.json
├── scripts/
│   ├── 00-start.sh
│   ├── 01-configure-vault.sh
│   ├── 02-test-success.sh
│   ├── 03-test-negative.sh
│   ├── 04-test-cutover.sh
│   └── 99-cleanup.sh
├── docs/
│   ├── context.md
│   ├── results.md
│   └── lab-next-steps.md
├── Makefile
└── README.md
```

## Prerequisites

Required:

```text
Docker or Colima
curl
jq
make
```

On macOS with Colima:

```bash
brew install docker colima jq
colima start --cpu 4 --memory 6 --disk 20
docker run --rm hello-world
```

## Run the PoC

Start Vault and the local OIDC/JWKS issuer:

```bash
make start
```

Configure Vault:

```bash
make configure
```

Run success and negative tests:

```bash
make test
```

Expected summary:

```text
PASS: cluster-b authenticated and read existing Vault secret path
PASS: cluster-a authenticated and read existing Vault secret path
PASS: denied due to namespace claim mismatch
PASS: denied due to saname claim mismatch
PASS: denied due to cluster claim mismatch
SUCCESS: negative access-control tests passed.
```

Optional post-cutover test:

```bash
make cutover
```

This deletes the source-cluster Vault role and confirms the old source identity can no longer authenticate.

Clean up:

```bash
make cleanup
```

## Test Scenarios

| Scenario | Input claims | Expected result |
|---|---|---|
| Destination cluster access | `cluster-b / sales / sales-app-sa` | Allowed |
| Source cluster dual-run | `cluster-a / sales / sales-app-sa` | Allowed |
| Wrong namespace | `cluster-b / finance / sales-app-sa` | Denied |
| Wrong service account | `cluster-b / sales / wrong-sa` | Denied |
| Wrong cluster | `cluster-c / sales / sales-app-sa` | Denied |
| Post-cutover cleanup | delete `sales-cluster-a` role | Source cluster denied |

## Important Implementation Detail

The Vault Docker image may fail under some Colima/macOS environments when using its default entrypoint because of Linux capability handling.

To keep the PoC reproducible, this repo bypasses the container entrypoint and starts Vault directly:

```yaml
entrypoint: ["vault"]
command: ["server", "-dev", "-dev-no-store-token"]
```

This is only for the local PoC. It is not a production Vault deployment pattern.

## Mapping to Real Tremolo/OpenUnison STS

In the real implementation:

```text
1. Pod runs with Kubernetes ServiceAccount.
2. OpenUnison/Tremolo STS sidecar receives the pod ServiceAccount token.
3. STS validates it using Kubernetes TokenReview.
4. STS issues a short-lived JWT scoped for Vault.
5. Vault validates the JWT using the STS issuer OIDC/JWKS endpoint.
6. Vault grants a Vault token only if bound claims match the configured role.
7. Vault policy controls which secret paths can be read.
```

This local PoC simulates steps 4 through 7.

## References

- Tremolo: Short Lived Tokens With Vault Without The Static ServiceAccount  
  https://www.tremolo.io/post/short-lived-tokens-with-vault-without-the-static-serviceaccount

- HashiCorp Vault JWT/OIDC auth  
  https://developer.hashicorp.com/vault/docs/auth/jwt

- HashiCorp Vault Kubernetes auth  
  https://developer.hashicorp.com/vault/docs/auth/kubernetes

## Security Note

This repository uses only sanitized sample names and fake local data:

```text
cluster-a
cluster-b
sales
sales-app-sa
existing-sales-secret
```

