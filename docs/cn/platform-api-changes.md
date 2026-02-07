# 平台 API 变更说明

本文档描述精简版平台部署的 API 变化。

## 概述

精简版平台引入了新的一步注册 API，同时保持与现有 API 的向后兼容。

## 新增 API

### POST /v2/platform/spaces

**用途**: 一步完成空间注册。将盒子、用户、客户端注册合并为单次调用。

**使用场景**: 新的集成或精简部署场景。

**请求头**:
| 头部 | 必需 | 描述 |
|------|------|------|
| Request-Id | 是 | 唯一请求标识符 |
| Content-Type | 是 | `application/json` |

**请求体**:
```json
{
  "boxUUID": "字符串 (必需)",
  "userId": "字符串 (必需)",
  "clientUUID": "字符串 (必需)",
  "subdomain": "字符串 (可选, 6-20字符, 小写字母和数字, 必须以字母开头)",
  "userType": "字符串 (可选, 默认: user_admin, 可选值: user_admin, user_member)"
}
```

**响应** (200 OK):
```json
{
  "boxUUID": "字符串",
  "userId": "字符串",
  "clientUUID": "字符串",
  "subdomain": "字符串",
  "userDomain": "字符串 (完整域名, 如: myspace.example.com)",
  "userType": "字符串",
  "networkClient": {
    "clientId": "字符串 (NAT穿透用的网络客户端ID)",
    "secretKey": "字符串 (网络密钥)"
  }
}
```

**错误响应**:
| 状态码 | 错误码 | 描述 |
|--------|--------|------|
| 400 | - | 请求无效 (验证失败) |
| 409 | SUBDOMAIN_ALREADY_USED | 请求的子域名已被占用 |

**示例**:
```bash
curl -X POST https://platform.example.com/v2/platform/spaces \
  -H "Content-Type: application/json" \
  -H "Request-Id: $(uuidgen)" \
  -d '{
    "boxUUID": "550e8400-e29b-41d4-a716-446655440000",
    "userId": "admin-001",
    "clientUUID": "client-001",
    "subdomain": "myspace"
  }'
```

---

### DELETE /v2/platform/spaces/{box_uuid}

**用途**: 删除整个空间注册 (盒子、所有用户、客户端、子域名)。

**请求头**:
| 头部 | 必需 | 描述 |
|------|------|------|
| Request-Id | 是 | 唯一请求标识符 |

**响应**: 204 No Content

---

### GET /v2/platform/spaces/{box_uuid}

**用途**: 获取空间注册详情。

**响应**: 与现有 `boxRegistryBindUserAndClientInfo` 格式相同。

---

## 保留的 API (向后兼容)

以下现有 API 保持完全可用:

### 注册 API
| 方法 | 端点 | 描述 |
|------|------|------|
| POST | /v2/platform/boxes | 注册盒子 |
| DELETE | /v2/platform/boxes/{box_uuid} | 删除盒子 |
| POST | /v2/platform/boxes/{box_uuid}/users | 注册用户 |
| DELETE | /v2/platform/boxes/{box_uuid}/users/{user_id} | 删除用户 |
| POST | /v2/platform/boxes/{box_uuid}/users/{user_id}/clients | 注册客户端 |
| DELETE | /v2/platform/boxes/{box_uuid}/users/{user_id}/clients/{client_uuid} | 删除客户端 |
| POST | /v2/platform/boxes/{box_uuid}/subdomains | 生成子域名 |
| PUT | /v2/platform/boxes/{box_uuid}/users/{user_id}/subdomain | 更新子域名 |

### Token API
| 方法 | 端点 | 描述 |
|------|------|------|
| POST | /v2/platform/auth/box_reg_keys | 获取盒子注册密钥 |
| POST | /v2/platform/auth/box_reg_key/check | 验证盒子注册密钥 |

### 网络 API
| 方法 | 端点 | 描述 |
|------|------|------|
| POST | /v2/platform/clients/network/auth | 认证网络客户端 |
| GET | /v2/platform/servers/network/detail | 获取网络服务器信息 |
| GET | /v2/platform/servers/stun/detail | 获取 STUN 服务器信息 |

### 状态 API
| 方法 | 端点 | 描述 |
|------|------|------|
| GET | /v2/platform/status | 平台状态和版本 |
| GET | /v2/platform/ability | 平台能力 |

---

## 可弃用的 API (可选移除)

以下 API 在精简部署中可以禁用:

### Auth/Pkey API (扫码登录)
| 方法 | 端点 | 描述 |
|------|------|------|
| POST | /v2/platform/pkeys | 生成 pkey |
| POST | /v2/platform/pkeys/{pkey}/boxinfo | 发送盒子公钥 |
| GET | /v2/platform/pkeys/{pkey}/boxinfo | 获取盒子公钥 |

### 迁移 API
| 方法 | 端点 | 描述 |
|------|------|------|
| POST | /v2/platform/boxes/{box_uuid}/migration | 平台割接 |
| POST | /v2/platform/boxes/{box_uuid}/route | 域名重定向 |

---

## 客户端集成指南

### 服务端 (space-agent)

**选项A: 使用新的简化 API**

将当前的多步注册替换为单次调用:

```go
// 之前 (多步骤):
// 1. POST /v2/platform/auth/box_reg_keys
// 2. POST /v2/platform/boxes (带 Box-Reg-Key 头)
// 3. POST /v2/platform/boxes/{box_uuid}/users
// 4. POST /v2/platform/boxes/{box_uuid}/users/{user_id}/clients

// 之后 (单步骤):
// POST /v2/platform/spaces
type SpaceRegistryRequest struct {
    BoxUUID    string `json:"boxUUID"`
    UserID     string `json:"userId"`
    ClientUUID string `json:"clientUUID"`
    Subdomain  string `json:"subdomain,omitempty"`
    UserType   string `json:"userType,omitempty"`
}

type SpaceRegistryResponse struct {
    BoxUUID       string        `json:"boxUUID"`
    UserID        string        `json:"userId"`
    ClientUUID    string        `json:"clientUUID"`
    Subdomain     string        `json:"subdomain"`
    UserDomain    string        `json:"userDomain"`
    UserType      string        `json:"userType"`
    NetworkClient NetworkClient `json:"networkClient"`
}

type NetworkClient struct {
    ClientID  string `json:"clientId"`
    SecretKey string `json:"secretKey"`
}
```

**选项B: 保持现有流程**

现有的注册流程继续有效。无需更改。

---

### 客户端 (Android/iOS/Web)

**无需立即更改。**

客户端与服务器 (space-agent) 交互，不直接与平台交互。服务器处理平台注册。

**未来考虑**: 如果实现直接平台集成，使用新的 `/v2/platform/spaces` 端点。

---

## 配置变更

### DNS 记录 (简化)

**之前** (7条记录):
```
A  example.com          -> IP
A  services.example.com -> IP
A  *.example.com        -> IP
A  *.res.example.com    -> IP
A  *.update.example.com -> IP
A  *.download.example.com -> IP
A  *.push.example.com   -> IP
```

**之后** (2条记录):
```
A  example.com   -> IP
A  *.example.com -> IP
```

### SSL 证书

**之前**: 多个 SAN 条目或多个证书
**之后**: 单个通配符证书 `*.example.com` + `example.com`

---

## 迁移指南

### 从完整平台迁移到精简版

1. **备份数据**:
   ```bash
   docker exec aoplatform-mysql mysqldump -u root -p aoplatform > backup.sql
   ```

2. **更新 compose 文件**:
   ```bash
   cd deploy/platform
   cp docker-compose.simple.yml docker-compose.yml
   cp .env.simple.example .env
   # 编辑 .env 配置
   ```

3. **重启服务**:
   ```bash
   docker compose down
   docker compose up -d
   ```

4. **重新初始化网络**:
   ```bash
   ./scripts/init-network.sh
   ```

### 现有注册保持有效

精简版平台使用相同的数据库结构。现有的盒子/用户/客户端注册将继续有效。

---

## API 对比表

| 功能 | 旧 API | 新 API | 备注 |
|------|--------|--------|------|
| 注册盒子 | POST /boxes + Box-Reg-Key | POST /spaces | 无需 Token |
| 注册用户 | POST /boxes/{id}/users | (包含在 /spaces 中) | 合并 |
| 注册客户端 | POST /boxes/{id}/users/{id}/clients | (包含在 /spaces 中) | 合并 |
| 获取网络凭证 | (在盒子注册响应中) | (在 /spaces 响应中) | 相同格式 |
| 删除空间 | DELETE /boxes/{id} | DELETE /spaces/{id} | 相同效果 |
| 子域名 | 自动或手动 | 自动或手动 | 相同 |

---

## 服务端修改清单

`space-agent` 需要进行以下修改:

### 1. 新增平台客户端方法

```go
// pkg/platform/client.go

// RegisterSpace 一步完成空间注册
func (c *Client) RegisterSpace(ctx context.Context, req *SpaceRegistryRequest) (*SpaceRegistryResponse, error) {
    // POST /v2/platform/spaces
}
```

### 2. 修改绑定流程

```go
// biz/service/bind/bind.go

// 选项A: 替换现有注册逻辑
func (s *Service) BindAdmin(ctx context.Context, ...) error {
    // 使用 RegisterSpace 替代多步注册
    resp, err := s.platformClient.RegisterSpace(ctx, &SpaceRegistryRequest{
        BoxUUID:    boxUUID,
        UserID:     userID,
        ClientUUID: clientUUID,
        Subdomain:  subdomain, // 可选
    })
    // 保存 resp.NetworkClient 凭证
}

// 选项B: 保持现有逻辑不变
// 现有的多步注册流程继续有效
```

### 3. 配置更新

```yaml
# config.yml
platform:
  # 新增选项: 使用简化 API
  use_simple_api: true  # 默认 false，保持兼容
```

---

## 错误码

新 API 的错误码:

| 错误码 | HTTP 状态 | 描述 |
|--------|-----------|------|
| SUBDOMAIN_ALREADY_USED | 409 | 请求的子域名已被其他盒子占用 |
| SUBDOMAIN_INVALID | 400 | 子域名格式无效 |
| BOX_NOT_REGISTERED | 404 | 盒子未找到 (用于 GET/DELETE) |
