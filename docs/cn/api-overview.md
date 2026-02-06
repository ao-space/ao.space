# API 概览

本项目包含多个服务的 API。下面是本地/自建部署时的主要入口。

## space-gateway
1. 基础路径：`/space`
2. Swagger UI：`http://<host>:<gateway_port>/space/q/swagger-ui/`

## space-aofs（文件服务）
1. 基础路径：`/space/v1/api`
2. Swagger UI：`http://<host>:<fileapi_port>/space/v1/api/swagger/index.html`

## space-agent
1. 基础路径：`/agent/v1/api`
2. 默认关闭 Swagger。  
   在 `system-agent.yml` 中设置 `DebugMode: true` 后访问：
   `http://<host>:<agent_port>/swagger/index.html`
