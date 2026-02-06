# API Overview

This project exposes APIs from multiple services. Below are the main entry points for local/self-hosted deployments.

## space-gateway
1. Base path: `/space`
2. Swagger UI: `http://<host>:<gateway_port>/space/q/swagger-ui/`

## space-aofs (file service)
1. Base path: `/space/v1/api`
2. Swagger UI: `http://<host>:<fileapi_port>/space/v1/api/swagger/index.html`

## space-agent
1. Base path: `/agent/v1/api`
2. Swagger UI is disabled by default.  
   Enable `DebugMode: true` in `system-agent.yml`, then access:
   `http://<host>:<agent_port>/swagger/index.html`
