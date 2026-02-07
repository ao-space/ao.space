# 平台端精简方案

## 一、当前架构分析

### 1.1 现有容器组成 (7个)

| 容器 | 用途 | 是否必须 |
|------|------|---------|
| aoplatform-mysql | 数据存储 | 是 |
| aoplatform-redis | 缓存/路由 | 是 |
| aoplatform-services | 核心API服务 | 是 |
| aoplatform-proxy | Lua路由转发 | 是 |
| aoplatform-nginx | HTTPS终止 | 是 |
| aonetwork-server (gt) | NAT穿透 | 是 |
| aoplatform-mysql-update | 初始化网络信息 | 可合并 |

### 1.2 当前注册流程 (复杂)

```
1. 服务端获取 box_reg_key (POST /v2/platform/auth/box_reg_keys)
   ↓
2. 注册盒子 (POST /v2/platform/boxes)
   ← 返回 network_client_id + network_secret_key
   ↓
3. 注册用户 (POST /v2/platform/boxes/{box_uuid}/users)
   ← 自动分配 subdomain
   ↓
4. 注册客户端 (POST /v2/platform/boxes/{box_uuid}/users/{user_id}/clients)
   ↓
5. 可选：申请额外 subdomain (POST /v2/platform/boxes/{box_uuid}/subdomains)
6. 可选：更新 subdomain (PUT /v2/platform/boxes/{box_uuid}/users/{user_id}/subdomain)
```

### 1.3 域名结构 (复杂)

当前需要配置多个子域名：
- `example.com` - 主域名，平台API
- `services.example.com` - 平台服务
- `*.example.com` - 用户空间访问
- `*.res.example.com` - 资源访问
- `*.update.example.com` - 更新服务
- `*.download.example.com` - 下载服务
- `*.push.example.com` - 推送服务

---

## 二、精简目标

### 2.1 部署目标
- 单机 Docker Compose 一键部署
- 适合个人/小团队维护
- 最小化外部依赖
- 清晰的域名/证书配置

### 2.2 功能精简
- 保留核心功能：设备注册、域名分配、网络穿透
- 移除：平台割接(migration)、复杂的多级子域名
- 简化：注册流程、Token验证

---

## 三、DNS/域名/证书需求

### 3.1 精简后域名结构

只需要配置 **2条DNS记录**：

| 类型 | 名称 | 值 | 用途 |
|------|------|-----|------|
| A | `platform.example.com` | 服务器IP | 平台API |
| A | `*.example.com` | 服务器IP | 用户空间访问 |

### 3.2 SSL证书需求

需要一张 **泛域名证书**，覆盖：
- `example.com`
- `*.example.com`

### 3.3 端口需求

| 端口 | 协议 | 用途 |
|------|------|------|
| 80 | TCP | HTTP → HTTPS 重定向 |
| 443 | TCP | HTTPS 服务 |
| 443 | TCP | GT Server (NAT穿透) |
| 3478 | UDP | STUN (P2P协商) |

**注意**: 443端口被 nginx 和 gt-server 共用，需要通过SNI或不同IP区分。

---

## 四、Cloudflare 配置说明

### 4.1 DNS 配置

登录 Cloudflare Dashboard → 选择域名 → DNS

```
类型    名称              内容              代理状态    TTL
────────────────────────────────────────────────────────────
A       platform          YOUR_SERVER_IP    DNS only    Auto
A       *                 YOUR_SERVER_IP    DNS only    Auto
```

**重要**:
- 必须使用 **DNS only** (灰色云朵)，不能使用 Cloudflare 代理
- 因为 GT Server 需要直接 TCP/UDP 连接

### 4.2 SSL/TLS 证书获取

**方法一：Cloudflare Origin Certificate (推荐)**

1. SSL/TLS → Origin Server → Create Certificate
2. 私钥类型: RSA (2048)
3. 主机名: `*.example.com`, `example.com`
4. 有效期: 15年
5. 下载证书 (tls.crt) 和私钥 (tls.key)

**方法二：Let's Encrypt (acme.sh)**

```bash
# 安装 acme.sh
curl https://get.acme.sh | sh

# 使用 Cloudflare DNS API 获取证书
export CF_Token="your-cloudflare-api-token"
export CF_Zone_ID="your-zone-id"

acme.sh --issue --dns dns_cf \
  -d example.com \
  -d '*.example.com'

# 证书路径
# ~/.acme.sh/example.com/example.com.cer
# ~/.acme.sh/example.com/example.com.key
```

### 4.3 证书部署

```bash
mkdir -p deploy/platform/data/ssl
cp tls.crt deploy/platform/data/ssl/
cp tls.key deploy/platform/data/ssl/
chmod 600 deploy/platform/data/ssl/tls.key
```

---

## 五、简化注册逻辑方案

### 5.1 当前问题

1. **Token 机制复杂**: 需要先获取 box_reg_key，24小时过期
2. **多层注册**: Box → User → Client 三层嵌套
3. **Subdomain 分配复杂**: 临时状态、过期管理、推荐算法

### 5.2 简化方案

#### 方案A: 合并注册接口 (推荐)

新增一个简化接口，一次性完成所有注册：

```
POST /v2/platform/spaces
Request:
{
  "box_uuid": "xxx",
  "user_id": "xxx",
  "client_uuid": "xxx",
  "subdomain": "myspace"  // 可选，不填则自动生成
}

Response:
{
  "box_uuid": "xxx",
  "user_id": "xxx",
  "client_uuid": "xxx",
  "subdomain": "myspace",
  "user_domain": "myspace.example.com",
  "network_client_id": "xxx",
  "network_secret_key": "xxx"
}
```

#### 方案B: 移除 Token 验证 (单机场景)

对于私有部署，可以移除 box_reg_key 验证：
- 使用 IP 白名单或内网访问
- 或使用简单的 API Key

#### 方案C: 简化 Subdomain 管理

- 移除临时状态，直接分配
- 移除过期机制
- 移除推荐算法
- 用户自选 subdomain，冲突则返回错误

### 5.3 精简后注册流程

```
1. 一次性注册 (POST /v2/platform/spaces)
   ↓
2. 完成！返回 network_client_id 和用户域名
```

---

## 六、精简后的部署方案

### 6.1 新的 docker-compose.yml

```yaml
version: "3.8"

services:
  # 数据库 - MySQL
  aoplatform-mysql:
    container_name: aoplatform-mysql
    image: mysql:8.0
    command: --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
    volumes:
      - ${DATA_DIR}/mysql:/var/lib/mysql
    healthcheck:
      test: mysqladmin ping -h 127.0.0.1 -u $$MYSQL_USER --password=$$MYSQL_PASSWORD
      interval: 10s
      timeout: 5s
      retries: 5

  # 缓存 - Redis
  aoplatform-redis:
    container_name: aoplatform-redis
    image: redis:7-alpine
    command: redis-server --requirepass ${REDIS_PASSWORD} --save 60 1 --appendonly yes
    restart: unless-stopped
    volumes:
      - ${DATA_DIR}/redis:/data
    healthcheck:
      test: redis-cli -a $$REDIS_PASSWORD ping
      interval: 10s
      timeout: 5s
      retries: 5

  # 核心服务 - Platform Base
  aoplatform-services:
    container_name: aoplatform-services
    build:
      context: ../../platform/platform-base
      dockerfile: Dockerfile
    restart: unless-stopped
    depends_on:
      aoplatform-mysql:
        condition: service_healthy
      aoplatform-redis:
        condition: service_healthy
    environment:
      QUARKUS_DATASOURCE_USERNAME: ${MYSQL_USER}
      QUARKUS_DATASOURCE_PASSWORD: ${MYSQL_PASSWORD}
      QUARKUS_DATASOURCE_JDBC_URL: jdbc:mysql://aoplatform-mysql:3306/${MYSQL_DATABASE}?allowPublicKeyRetrieval=true&useSSL=false&serverTimezone=GMT%2B8
      QUARKUS_REDIS_HOSTS: redis://aoplatform-redis:6379/0
      QUARKUS_REDIS_PASSWORD: ${REDIS_PASSWORD}
      APP_REGISTRY_SUBDOMAIN: ${USER_DOMAIN}
    healthcheck:
      test: curl --fail http://127.0.0.1:8080/v2/platform/status -H 'Request-Id:health'
      interval: 10s
      timeout: 5s
      retries: 5

  # 路由代理 - OpenResty
  aoplatform-proxy:
    container_name: aoplatform-proxy
    build:
      context: ../../platform/platform-proxy
      dockerfile: Dockerfile
    restart: unless-stopped
    depends_on:
      aoplatform-redis:
        condition: service_healthy
    environment:
      REDIS_ADDR: aoplatform-redis
      REDIS_PORT: 6379
      REDIS_PASSWORD: ${REDIS_PASSWORD}
    healthcheck:
      test: curl --fail http://127.0.0.1/healthcheck
      interval: 10s
      timeout: 5s
      retries: 5

  # HTTPS终止 - Nginx
  aoplatform-nginx:
    container_name: aoplatform-nginx
    build:
      context: ../../platform/platform-nginx
      dockerfile: Dockerfile
    restart: unless-stopped
    depends_on:
      aoplatform-services:
        condition: service_healthy
      aoplatform-proxy:
        condition: service_healthy
    network_mode: host
    environment:
      USER_DOMAIN: ${USER_DOMAIN}
      NGINX_BIND_HTTP: 80
      NGINX_BIND_HTTPS: 443
      PROXY_LOCAL_BIND: 61011
      SERVICES_LOCAL_BIND: 61013
    volumes:
      - ${DATA_DIR}/ssl:/etc/nginx/ssl:ro

  # NAT穿透 - GT Server
  aonetwork-server:
    container_name: aonetwork-server
    image: hub.eulix.xyz/ao-space/gt:server-v1.0.0
    restart: unless-stopped
    depends_on:
      aoplatform-services:
        condition: service_healthy
    ports:
      - "61012:443/tcp"
      - "3478:3478/udp"
    environment:
      NETWORK_TLSADDR: 443
      NETWORK_ADDR: 80
      NETWORK_LOGLEVEL: info
      NETWORK_API_ADDR: 0.0.0.0:81
      NETWORK_AUTHAPI: http://aoplatform-services:8080/v2/platform/clients/network/auth
      NETWORK_TIMEOUT: 75s
    volumes:
      - ${DATA_DIR}/ssl:/opt/crt:ro
```

### 6.2 新的 .env 文件

```env
# 数据目录
DATA_DIR=./data

# 域名配置 (必须修改)
USER_DOMAIN=example.com

# MySQL配置
MYSQL_ROOT_PASSWORD=your_secure_root_password
MYSQL_DATABASE=aoplatform
MYSQL_USER=aoplatform
MYSQL_PASSWORD=your_secure_password

# Redis配置
REDIS_PASSWORD=your_secure_redis_password
```

### 6.3 部署步骤

```bash
# 1. 克隆仓库
git clone https://github.com/ao-space/ao.space.git
cd ao.space
git submodule update --init platform/platform-base platform/platform-proxy platform/platform-nginx

# 2. 配置环境
cd deploy/platform
cp .env.example .env
# 编辑 .env，设置域名和密码

# 3. 配置SSL证书
mkdir -p data/ssl
cp /path/to/tls.crt data/ssl/
cp /path/to/tls.key data/ssl/

# 4. 初始化数据库 (首次运行)
docker compose up -d aoplatform-mysql aoplatform-redis
sleep 30  # 等待数据库就绪

# 5. 启动所有服务
docker compose up -d

# 6. 检查服务状态
docker compose ps
docker compose logs -f
```

---

## 七、代码改动清单

### 7.1 需要修改的文件

| 文件 | 改动 |
|------|------|
| `RegistryResource.java` | 新增 `/spaces` 简化注册接口 |
| `RegistryService.java` | 新增合并注册方法 |
| `TokenResource.java` | 可选：简化Token验证 |
| `MigrationResource.java` | 可删除或保留 |
| `entrypoint.sh` (nginx) | 简化域名配置 |
| `docker-compose.yml` | 合并 mysql-update 初始化 |

### 7.2 可删除的功能 (降低维护成本)

- [ ] Migration 平台割接功能
- [ ] Subdomain 推荐算法
- [ ] Subdomain 过期管理
- [ ] 多级子域名 (res/update/download/push)
- [ ] 扫码登录 (pkey认证)

### 7.3 需要保留的核心功能

- [x] Box/User/Client 注册
- [x] Subdomain 分配
- [x] Network Client 认证
- [x] GT路由缓存
- [x] HTTPS终止
- [x] NAT穿透

---

## 八、测试验证

### 8.1 健康检查

```bash
# 平台状态
curl -H "Request-Id: test" https://platform.example.com/v2/platform/status

# 平台能力
curl -H "Request-Id: test" https://platform.example.com/v2/platform/ability
```

### 8.2 注册测试

```bash
# 使用精简接口注册
curl -X POST https://platform.example.com/v2/platform/spaces \
  -H "Content-Type: application/json" \
  -H "Request-Id: test-$(date +%s)" \
  -d '{
    "box_uuid": "test-box-001",
    "user_id": "admin",
    "client_uuid": "client-001",
    "subdomain": "myspace"
  }'
```

### 8.3 访问测试

```bash
# 用户空间访问 (需要服务端运行)
curl -k https://myspace.example.com/
```

---

## 九、后续改进建议

1. **Traefik 替代 Nginx**: 自动HTTPS证书管理
2. **SQLite 替代 MySQL**: 进一步简化单机部署
3. **内嵌 Redis**: 使用 Quarkus 内嵌缓存
4. **统一镜像**: 将所有服务打包为单个容器
5. **Web管理界面**: 可视化配置和监控

---

## 十、总结

| 项目 | 精简前 | 精简后 |
|------|--------|--------|
| 容器数量 | 7个 | 6个 |
| DNS记录 | 7条 | 2条 |
| 注册步骤 | 4步 | 1步 |
| SSL证书 | 多域名 | 泛域名 |
| 维护复杂度 | 高 | 低 |

---

## 十一、实施状态

### 已完成的修改

| 文件 | 修改内容 | 状态 |
|------|----------|------|
| `platform/platform-base/.../dto/registry/SpaceRegistryInfo.java` | 新增简化注册请求 DTO | ✅ |
| `platform/platform-base/.../dto/registry/SpaceRegistryResult.java` | 新增简化注册响应 DTO | ✅ |
| `platform/platform-base/.../rest/SpaceResource.java` | 新增 `/spaces` REST 接口 | ✅ |
| `platform/platform-base/.../service/RegistryService.java` | 新增 `registerSpace()` 方法 | ✅ |
| `platform/platform-base/.../rest/SpaceResourceTest.java` | 新增测试用例 | ✅ |
| `platform/platform-nginx/entrypoint-simple.sh` | 简化的 nginx 配置脚本 | ✅ |
| `platform/platform-nginx/Dockerfile.simple` | 使用简化配置的 Dockerfile | ✅ |
| `deploy/platform/docker-compose.simple.yml` | 精简版 docker-compose | ✅ |
| `deploy/platform/.env.simple.example` | 精简版环境变量示例 | ✅ |
| `deploy/platform/scripts/init-network.sh` | 网络初始化脚本 | ✅ |
| `deploy/platform/README-simple.md` | 精简部署说明 | ✅ |
| `docs/en/platform-api-changes.md` | API 变更文档 (英文) | ✅ |
| `docs/cn/platform-api-changes.md` | API 变更文档 (中文) | ✅ |

### 新增文件列表

```
platform/platform-base/eulixplatform-registry/src/main/java/xyz/eulix/platform/services/registry/
├── dto/registry/
│   ├── SpaceRegistryInfo.java      # 新增
│   └── SpaceRegistryResult.java    # 新增
└── rest/
    └── SpaceResource.java          # 新增

platform/platform-base/eulixplatform-registry/src/test/java/xyz/eulix/platform/services/registry/rest/
└── SpaceResourceTest.java          # 新增

platform/platform-nginx/
├── entrypoint-simple.sh            # 新增
└── Dockerfile.simple               # 新增

deploy/platform/
├── docker-compose.simple.yml       # 新增
├── .env.simple.example             # 新增
├── init-db.sql                     # 新增
├── scripts/
│   └── init-network.sh             # 新增
└── README-simple.md                # 新增

docs/
├── en/platform-api-changes.md      # 新增
└── cn/platform-api-changes.md      # 新增
```

### 服务端和客户端需要的修改

详见 `docs/en/platform-api-changes.md` 和 `docs/cn/platform-api-changes.md`

#### 服务端 (space-agent) 修改要点:

1. **可选**: 使用新的 `POST /v2/platform/spaces` API 替代多步注册
2. **保持兼容**: 现有注册流程继续有效，无需强制修改
3. **配置项**: 可添加 `use_simple_api` 开关切换新旧 API

#### 客户端 (Android/iOS/Web) 修改要点:

1. **无需修改**: 客户端通过服务端间接与平台交互
2. **未来考虑**: 如需直连平台，使用新 API
