# API 测试与接口清单（精简部署）

## 范围
当前以“最精简可运行”模式为目标：`space-aofs + space-agent + space-gateway`，不依赖平台端。
接口清单以代码路由为准（不是历史文档）。

## 服务端真实 API 清单
### space-aofs（`/space/v1/api`）
1. 文件：`GET /file/info` `GET /file/list` `POST /file/rename` `POST /file/copy` `POST /file/move` `POST /file/delete` `GET /file/download` `GET /file/search` `GET /file/thumb` `GET /file/compressed` `POST /file/vod/symlink`
2. 目录：`POST /folder/create` `GET /folder/info`
3. 用户：`POST /user/init` `POST /user/delete` `GET /user/storage`
4. 回收站：`GET /recycled/list` `POST /recycled/restore` `GET|POST /recycled/clear`
5. 分片：`POST /multipart/create` `POST /multipart/upload` `GET /multipart/list` `POST /multipart/complete` `POST /multipart/delete`
6. 其他：`GET /sync/synced` `GET /async/task` `GET /status` `GET /inner/file/info` `POST /inner/file/infos`

### space-agent
1. 外部：`/agent/v1/api/*`（pair/bind/network/did/switch/passthrough 等）+ `GET /agent/status` `GET /agent/info`
2. 内部：`/agent/v1/api/device/*` `/upgrade/*` `/network/*` `/system/*` `/cert/get` `/bind/internet/service/config` `/did/*`

## Android 侧差异（优先关注）
`client/client-android/app/src/main/java/xyz/eulix/space/util/ConstantField.java` 中大量常量依赖 `gateway/platform` 能力。

精简模式可直接覆盖：文件、目录、回收站、分片、`/space/v1/api/status`、`agent` 基础链路，以及 `gateway` 基础入口（如版本查询）。

需暂不支持或后续接入：平台强耦合接口（`member/personal/security/notification` 全量能力）、`agent` 的 `reset/authinfo/disk/*/upgrade/start-*` 等未注册路由，以及依赖完整业务初始化状态的接口。

## 已落地测试代码
1. 路由契约测试（防止接口被误删）
- `server/space-aofs/routers/routers/routes_contract_test.go`
- `server/space-agent/biz/web/routers/routes_contract_test.go`
2. 在线 smoke：`scripts/api-smoke.sh`
3. 回归断言脚本（含业务码校验）：`scripts/api-regression.sh`
4. 写链路端到端：`scripts/api-e2e-write.sh`
5. 分片链路端到端：`scripts/api-e2e-multipart.sh`
6. 全量回归入口：`scripts/api-full-regression.sh`
7. 错误码契约：`docs/cn/api-error-contract.md`

## 关键回归断言
1. `GET /space/v1/api/status`：无 `userId` 时也必须返回 `code=200`（健康检查无参可用）。
2. `GET /space/v1/api/file/list`：缺少 `userId` 必须返回 `code=1001`，不得出现连接中断。
3. `GET /space/v1/api/async/task?userId=1`：缺少 `taskId` 当前返回 `code=1062`（任务不存在）。
4. Agent 基础可用性：`/agent/status`、`/agent/info` 返回 `code=AG-200`。
5. Gateway 基础可用性：`/space/v1/api/gateway/version/box/current` 无 `Request-Id` 返回 `GW-400`，有 `Request-Id` 返回 `GW-200`。

## 执行命令
1. `cd server/space-aofs && go test ./routers/routers -run TestInitRoute_RegistersExpectedAPIs`
2. `cd server/space-agent && go test ./biz/web/routers -run Test.*Router_RegistersExpectedAPIs`
3. 启动服务后：`AOFS_BASE=http://127.0.0.1:8090 AGENT_BASE=http://127.0.0.1:5680 ./scripts/api-smoke.sh`
4. 全量回归：`AOFS_BASE=http://127.0.0.1:8090 AGENT_BASE=http://127.0.0.1:5680 ./scripts/api-regression.sh`
5. 写链路回归：`AOFS_BASE=http://127.0.0.1:8090 ./scripts/api-e2e-write.sh`
6. 分片链路回归：`AOFS_BASE=http://127.0.0.1:8090 ./scripts/api-e2e-multipart.sh`
7. 一键全量：`AOFS_BASE=http://127.0.0.1:8090 AGENT_BASE=http://127.0.0.1:5680 ./scripts/api-full-regression.sh`

## iOS 回归（2026-02-07）
1. 命令：`cd client/client-ios && xcodebuild -workspace EulixSpace.xcworkspace -scheme EulixSpace -destination "platform=iOS Simulator,name=iPhone 16,OS=18.0" -only-testing:EulixSpaceTests test`
2. 结果：`12 passed, 0 failed`
3. 重点覆盖：
- 历史 box 请求拦截（防止回切旧盒子地址）
- LAN host 覆盖仅允许同一 boxUUID
- LAN cert 响应解析兼容（string / dict / nested dict）

## Web 回归与日志（2026-02-07）
1. 单测命令：`cd server/space-web && npm run test:unit`
2. 构建命令：`cd server/space-web && npm run build`
3. Web 基础链路 smoke：`./scripts/web-smoke.sh`
4. 日志开关：
- `localStorage.setItem('APP_LOG_LEVEL', 'debug')`：开启详细日志（推荐调试时使用）
- `localStorage.setItem('APP_LOG_LEVEL', 'info')`：恢复默认日志级别
- `localStorage.setItem('showLog', '1')`：兼容旧开关，等价于 debug
5. 关键日志位置：
- 登录切换：`src/pages/login/switchLogin.vue`
- 二维码登录：`src/pages/login/qrLogin.vue`
- 网关请求封装：`src/api/network.js`
- 上传链路：`src/business/fileUp/sequelUpUtilNew.ts`
