# AO.space Platform Deploy (Single VM)

This setup deploys the platform components on one VM with Docker.

## Requirements
1. Public IP and DNS you control
2. Wildcard TLS certificate for `${USER_DOMAIN}`
3. Ports 80, 443, 61012 TCP/UDP reachable from the Internet

## Quick Start
1. Copy `deploy/platform/.env.example` to `.env` and edit values.
2. Place TLS certs under `${AOPLATFORM_DATA_DIR}/ssl`.
3. Run:

```bash
cd deploy/platform
docker compose --env-file .env up -d
```

## Notes
1. This compose uses published platform images.
2. If you need custom builds, replace image entries with your own tags.
