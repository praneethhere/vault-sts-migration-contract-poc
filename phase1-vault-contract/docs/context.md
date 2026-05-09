# Context

This PoC validates a safe Vault access model for a Kubernetes namespace migration.

The migration scenario is:

```text
source cluster       -> destination cluster
same namespace       -> same namespace
same service account -> same service account
same Vault path      -> unchanged
```

The important security concern is that namespace names may be reused across clusters. Therefore, Vault authorization cannot rely on namespace alone.

The JWT identity must include at least:

```text
cluster
namespace
serviceAccount
audience
```

This allows Vault to distinguish:

```text
cluster-a / sales
cluster-b / sales
cluster-c / sales
```

The model tested here temporarily allows both source and destination identities during migration, then removes the source identity after cutover.
