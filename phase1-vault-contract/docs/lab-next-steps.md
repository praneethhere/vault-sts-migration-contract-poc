# Lab Next Steps

This local PoC validates the Vault-side JWT contract.

The next step is to validate the full Tremolo/OpenUnison STS flow in a Kubernetes lab.

## Required inputs

For one low-risk namespace:

```text
source cluster name
destination cluster name
namespace
serviceAccount name
existing Vault role or policy
existing Vault secret path
Vault auth path
expected audience value
```

## Lab validation steps

```text
1. Deploy OpenUnison/Tremolo STS.
2. Expose the STS issuer endpoint.
3. Validate OIDC discovery:
   curl https://<sts-issuer>/.well-known/openid-configuration
4. Validate JWKS:
   curl https://<sts-issuer>/certs
5. Configure Vault JWT auth to trust the STS issuer.
6. Configure Vault JWT role with bound audience and bound claims.
7. Deploy test pod with Vault Agent Injector and Tremolo STS annotations.
8. Confirm STS validates the pod ServiceAccount token.
9. Confirm STS writes the short-lived Vault token JWT.
10. Confirm Vault Agent uses the STS JWT to authenticate to Vault.
11. Confirm the application reads the existing Vault secret path.
12. Run negative tests for wrong namespace, wrong service account, and wrong cluster.
13. Remove source cluster binding after cutover and verify old access fails.
```

## Important distinction

The local PoC simulates the STS JWT.

The lab test must prove:

```text
real Kubernetes ServiceAccount token
real TokenReview validation
real OpenUnison/Tremolo STS sidecar injection
real Vault Agent Injector integration
real short-lived token refresh
```
