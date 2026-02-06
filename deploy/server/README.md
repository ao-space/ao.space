# AO.space Server Minimal Deploy

This setup runs the server components on one Docker host and keeps platform optional.

Components included:
1. `space-agent` (API + pairing only, docker management disabled)
2. `space-gateway`
3. `space-aofs`
4. `postgresql`
5. `redis`
6. `space-web` (web client + nginx)

Components excluded by default:
1. `space-filepreview`
2. `space-media-vod`
3. `space-upgrade`

## Optional Profiles
1. Enable file preview:

```bash
docker compose --env-file .env --profile preview up -d --build
```

2. Enable media VOD:

```bash
docker compose --env-file .env --profile vod up -d --build
```
## Quick Start
1. Copy `deploy/server/.env.example` to `.env` and edit passwords/ports.
2. Update `deploy/server/system-agent.yml` to match `.env` (Redis password).
3. Build images:

```bash
docker compose --env-file .env build
```

Notes:
1. `space-gateway` uses `server/space-gateway/Dockerfile.jvm.build` to compile Quarkus inside the build.
2. No-platform mode sets platform URLs to `http://127.0.0.1` to avoid SSL errors.

4. Run:

```bash
cd deploy/server
docker compose --env-file .env up -d --build
```

## Notes
1. Data is stored under `AOSPACE_DATA_DIR` (default `./data`).
2. `space-agent` docker management is disabled by `EnableDockerManage: false`.
3. If you want platform integration, set `PlatformEnabled: true` in `system-agent.yml` and deploy the platform.
4. `space-web` exposes `WEB_HTTP_PORT` and `WEB_HTTPS_PORT`.

## Core Regression Mode (AOFS + Agent + Gateway)
Use this mode when you want the smallest runnable backend that still supports client-side gateway flow.

Components:
1. `aospace-postgresql`
2. `aospace-redis`
3. `aospace-fileapi`
4. `aospace-agent`
5. `aospace-gateway`

Commands:
```bash
cp deploy/server/.env.aofs.example deploy/server/.env.aofs
scripts/aofs-regression.sh config
scripts/aofs-regression.sh up
scripts/aofs-regression.sh smoke
scripts/aofs-regression.sh logs
```

Notes:
1. `scripts/aofs-regression.sh up` auto-creates minimal meta/config files and required data folders.
2. `smoke` checks `fileapi + agent + gateway` endpoints inside containers; use `smoke-host` for host port mapping.
3. Stop stack with `scripts/aofs-regression.sh down`.
