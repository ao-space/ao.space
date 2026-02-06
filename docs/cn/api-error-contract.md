# API 错误码契约（精简部署）

本文档定义当前精简部署（`space-aofs + space-agent + space-gateway`）下，回归测试中必须稳定的错误码/返回码契约。

## space-aofs
1. `GET /space/v1/api/status`
- 预期：`code=200`
- 说明：健康检查接口允许无 `userId`。

2. `GET /space/v1/api/file/list`（缺少 `userId`）
- 预期：`code=1001`
- 说明：参数错误，必须返回业务错误，不允许连接中断。

3. `GET /space/v1/api/async/task?userId=1`（缺少 `taskId`）
- 预期：`code=1062`
- 说明：当前实现语义是“任务不存在”。

4. `POST /space/v1/api/multipart/upload`（重复分片）
- 预期：`code=1037`
- 说明：已上传范围重复。

## space-agent
1. `GET /agent/status`
2. `GET /agent/v1/api/pair/init`
3. `GET /agent/v1/api/space/ready/check`
- 预期：HTTP 200 且 `code=AG-200`
- 说明：`space-agent` 业务码是字符串，不是整数。

## space-gateway
1. `GET /space/v1/api/gateway/version/box/current`（无 `Request-Id`）
- 预期：HTTP `400` 且 `code=GW-400`

2. `GET /space/v1/api/gateway/version/box/current`（有 `Request-Id`）
- 预期：HTTP `200` 且 `code=GW-200`

## 契约执行入口
1. 基础断言：`scripts/api-regression.sh`
2. 写链路断言：`scripts/api-e2e-write.sh`
3. 分片链路断言：`scripts/api-e2e-multipart.sh`
4. 全量回归：`scripts/api-full-regression.sh`
