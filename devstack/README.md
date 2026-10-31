# devstack

Local development stack for TubeKeel. Production infrastructure lives in the private `keel-infra` repo.

## Local services

| Service | Port | Purpose |
|---|---|---|
| PostgreSQL 16 | `127.0.0.1:5432` | Core metadata, moderation ledger, payouts |
| LocalStack S3 | `127.0.0.1:4566` | S3-compatible object storage for local development |
| NATS JetStream | `127.0.0.1:4222` (client), `127.0.0.1:8222` (monitor) | Events and jobs |

## Run

```sh
# Optional: override the development defaults
cp devstack/.env.example devstack/.env
make infra-up
```

`make infra-up` reads `devstack/.env` automatically because the compose file lives in `devstack/`. The compose file also works without an env file by using its development defaults. The demo does not require these services yet.

The `localstack-init` container creates the `tubekeel` and `tubekeel-public` buckets on first start. The S3 endpoint is `http://localhost:4566`. LocalStack is a development emulator, not a production object store.

## Production notes

This compose file is for local development only. Ports bind to localhost, images are pinned to release tags, and development credentials are intentionally public. Production deployments should use managed PostgreSQL, an S3-compatible object store with a CDN, a hardened NATS cluster, secrets management, backups, and observability. Do not use the development credentials in production.
