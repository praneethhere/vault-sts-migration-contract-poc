# Real OpenUnison STS Runtime Results

## Summary

This phase validates the real runtime STS flow:

```text
Kubernetes ServiceAccount token
  -> OpenUnison/Tremolo STS exchange
  -> short-lived JWT written to /tokens/token.jwt
  -> Vault JWT auth
  -> Vault token with sales-existing policy
  -> existing Vault secret path read
```

## Validated runtime flow

A pod in namespace `sales` using service account `sales-app-sa` was created with the OpenUnison STS annotation.

The OpenUnison mutating webhook injected:

```text
sts-creds-sidecar
/tokens shared volume
VAULT_TOKEN_FILE=/tokens/token.jwt
```

The sidecar exchanged the pod ServiceAccount token with OpenUnison STS and generated:

```text
/tokens/token.jwt
/tokens/expires
/tokens/thumbprint
```

## Real STS JWT claims

The generated STS JWT included:

```json
{
  "iss": "https://<vault-sts-host>",
  "aud": "http://vault.vault.svc:8200",
  "sub": "kubernetes:sales:sales-app-sa",
  "cluster": "kubernetes",
  "namespace": "sales",
  "saname": "sales-app-sa"
}
```

## STS authorization rule

After identifying the real cluster claim, the STS authorization rule was tightened to:

```text
(&(namespace=sales)(saname=sales-app-sa)(cluster=kubernetes))
```

## Vault JWT auth validation

Vault was configured to trust the OpenUnison STS signing key and enforce the following bound claims:

```json
{
  "cluster": "kubernetes",
  "namespace": "sales",
  "saname": "sales-app-sa"
}
```

Vault successfully authenticated the real OpenUnison STS JWT and returned a Vault token with:

```text
default
sales-existing
```

## Secret access result

Using the Vault token returned from JWT auth, the pod identity successfully read the existing Vault path:

```text
secret/data/team-sales/config
```

The response contained the expected test secret:

```text
password = existing-sales-secret
```

## Conclusion

The full runtime PoC validates that OpenUnison/Tremolo STS can exchange a real Kubernetes ServiceAccount token for a short-lived Vault-scoped JWT, and Vault can enforce access using cluster, namespace, and service-account claims without copying or moving secrets.
