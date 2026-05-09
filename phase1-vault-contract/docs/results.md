# Test Results

## Environment

Validated locally on macOS using Docker through Colima.

Services:

```text
vault-sts-poc -> local Vault dev server
oidc-issuer   -> local fake STS/OIDC/JWKS issuer
```

Vault was started in dev mode for local testing only.

## Validated claims

The local issuer minted JWTs with these claims:

```text
iss       = http://oidc-issuer:8080
aud       = vault
cluster   = cluster-a or cluster-b
namespace = sales
saname    = sales-app-sa
sub       = cluster:namespace:saname
ttl       = 15 minutes
```

## Success case 1: destination cluster

Input:

```text
cluster-b / sales / sales-app-sa
role: sales-cluster-b
```

Result:

```text
Vault login succeeded.
Returned policy: sales-existing.
Secret read succeeded from secret/data/team-sales/config.
```

## Success case 2: source cluster dual-run

Input:

```text
cluster-a / sales / sales-app-sa
role: sales-cluster-a
```

Result:

```text
Vault login succeeded.
Returned policy: sales-existing.
```

## Negative case 1: wrong namespace

Input:

```text
cluster-b / finance / sales-app-sa
```

Result:

```text
Denied.
Vault error: claim "namespace" does not match any associated bound claim values.
```

## Negative case 2: wrong service account

Input:

```text
cluster-b / sales / wrong-sa
```

Result:

```text
Denied.
Vault error: claim "saname" does not match any associated bound claim values.
```

## Negative case 3: wrong cluster

Input:

```text
cluster-c / sales / sales-app-sa
```

Result:

```text
Denied.
Vault error: claim "cluster" does not match any associated bound claim values.
```

## Conclusion

The local contract test confirms that Vault can safely authorize access using cluster, namespace, and serviceAccount claims.

This supports the migration model where:

```text
1. Existing Vault secret path remains unchanged.
2. Destination cluster identity is added temporarily.
3. Source and destination can dual-run.
4. Source cluster access can be removed after cutover.
```
