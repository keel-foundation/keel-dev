# devstack

Local development stack for TubeKeel. Production infrastructure lives in the private `keel-infra` repo.

## Local services

| Service | Port | Purpose |
|---|---|---|
| PostgreSQL 16 | `5432` | Core metadata, moderation ledger, payouts |
| MinIO | `9000` (API), `9001` (console) | S3-compatible object storage |
| NATS JetStream | `4222` (client), `8222` (monitor) | Events and jobs |

## Run

```sh
# Optional: override the development defaults
cp devstack/.env.example devstack/.env
docker compose --env-file devstack/.env -f devstack/docker-compose.yml up -d
```

The compose file also works without an env file by using its development defaults.

The `minio-init` container creates the `tubekeel` and `tubekeel-public` buckets on first start. The console is at `http://localhost:9001`.

## Production notes

This compose file is for local development only. Production deployments should use managed PostgreSQL, an S3-compatible object store with a CDN, a hardened NATS cluster, secrets management, backups, and observability. Do not use the development credentials in production.
