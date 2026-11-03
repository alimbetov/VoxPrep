# Secrets

This directory contains no usable credentials in Git.

Local DEV/TEST secret files are generated with:

```bash
./infra/scripts/init-secrets.sh dev
./infra/scripts/init-secrets.sh test
```

or on Windows PowerShell:

```powershell
.\infra\scripts\init-secrets.ps1 -Environment dev
.\infra\scripts\init-secrets.ps1 -Environment test
```

Generated files are ignored by Git.

Production secrets are provisioned outside the repository, by default under:

```text
/etc/voxprep/secrets/prod/
```

Required secret file names:

```text
postgres_bootstrap_password
postgres_migrator_password
postgres_backend_password
rustfs_root_access_key
rustfs_root_secret_key
rustfs_backend_access_key
rustfs_backend_secret_key
```

## Plain Docker Compose permission model

The Compose files use file-backed `secrets:`. In ordinary non-Swarm Docker Compose these are bind mounts, so the container sees the source file permissions. PostgreSQL initialization and RustFS run as non-root users and must be able to read the mounted files.

For the current single-host Compose deployment use:

```text
secret directory: 0700, owned by the deployment administrator/root
secret files:     0444, inside that protected directory
```

The closed parent directory prevents ordinary host users from traversing to the files, while the read-only file mode lets the non-root container processes read the bind-mounted secret.

If the deployment later moves to native orchestrator secrets (Docker Swarm/Kubernetes/etc.), use that platform's tighter per-secret ownership/mode controls instead of preserving this Compose-specific workaround.

Never copy DEV/TEST credentials into PROD and never bake secret values into images, Compose YAML or tracked env files.
