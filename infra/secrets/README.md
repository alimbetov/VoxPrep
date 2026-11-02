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

Production files should be owned by the deployment administrator/root and readable only by the intended deployment process (`0600` or equivalent). Never copy DEV/TEST credentials into PROD.
