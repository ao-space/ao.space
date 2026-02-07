# Platform API Changes

This document describes the API changes for the simplified platform deployment.

## Overview

The simplified platform introduces a new one-step registration API while maintaining backward compatibility with existing APIs.

## New APIs

### POST /v2/platform/spaces

**Purpose**: One-step space registration. Combines box, user, and client registration into a single call.

**When to use**: For new integrations or simplified deployment scenarios.

**Request Headers**:
| Header | Required | Description |
|--------|----------|-------------|
| Request-Id | Yes | Unique request identifier |
| Content-Type | Yes | `application/json` |

**Request Body**:
```json
{
  "boxUUID": "string (required)",
  "userId": "string (required)",
  "clientUUID": "string (required)",
  "subdomain": "string (optional, 6-20 chars, lowercase letters and numbers, must start with letter)",
  "userType": "string (optional, default: user_admin, options: user_admin, user_member)"
}
```

**Response** (200 OK):
```json
{
  "boxUUID": "string",
  "userId": "string",
  "clientUUID": "string",
  "subdomain": "string",
  "userDomain": "string (full domain, e.g., myspace.example.com)",
  "userType": "string",
  "networkClient": {
    "clientId": "string (network client ID for NAT traversal)",
    "secretKey": "string (network secret key)"
  }
}
```

**Error Responses**:
| Status | Code | Description |
|--------|------|-------------|
| 400 | - | Invalid request (validation failed) |
| 409 | SUBDOMAIN_ALREADY_USED | Requested subdomain is taken |

**Example**:
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

**Purpose**: Delete entire space registration (box, all users, clients, subdomains).

**Request Headers**:
| Header | Required | Description |
|--------|----------|-------------|
| Request-Id | Yes | Unique request identifier |

**Response**: 204 No Content

**Example**:
```bash
curl -X DELETE https://platform.example.com/v2/platform/spaces/550e8400-e29b-41d4-a716-446655440000 \
  -H "Request-Id: $(uuidgen)"
```

---

### GET /v2/platform/spaces/{box_uuid}

**Purpose**: Get space registration details.

**Response**: Same as existing `boxRegistryBindUserAndClientInfo` format.

---

## Retained APIs (Backward Compatible)

These existing APIs remain fully functional:

### Registration APIs
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /v2/platform/boxes | Register box |
| DELETE | /v2/platform/boxes/{box_uuid} | Delete box |
| POST | /v2/platform/boxes/{box_uuid}/users | Register user |
| DELETE | /v2/platform/boxes/{box_uuid}/users/{user_id} | Delete user |
| POST | /v2/platform/boxes/{box_uuid}/users/{user_id}/clients | Register client |
| DELETE | /v2/platform/boxes/{box_uuid}/users/{user_id}/clients/{client_uuid} | Delete client |
| POST | /v2/platform/boxes/{box_uuid}/subdomains | Generate subdomain |
| PUT | /v2/platform/boxes/{box_uuid}/users/{user_id}/subdomain | Update subdomain |

### Token APIs
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /v2/platform/auth/box_reg_keys | Get box registration keys |
| POST | /v2/platform/auth/box_reg_key/check | Verify box registration key |

### Network APIs
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /v2/platform/clients/network/auth | Authenticate network client |
| GET | /v2/platform/servers/network/detail | Get network server info |
| GET | /v2/platform/servers/stun/detail | Get STUN server info |

### Status APIs
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /v2/platform/status | Platform status and version |
| GET | /v2/platform/ability | Platform capabilities |

---

## Deprecated APIs (Optional Removal)

These APIs can be disabled in simplified deployments:

### Auth/Pkey APIs (Scan login)
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /v2/platform/pkeys | Generate pkey |
| POST | /v2/platform/pkeys/{pkey}/boxinfo | Send box public key |
| GET | /v2/platform/pkeys/{pkey}/boxinfo | Get box public key |

### Migration APIs
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /v2/platform/boxes/{box_uuid}/migration | Platform migration |
| POST | /v2/platform/boxes/{box_uuid}/route | Domain redirect |

---

## Client Integration Guide

### For Server (space-agent)

**Option A: Use new simplified API**

Replace the current multi-step registration with a single call:

```go
// Before (multiple steps):
// 1. POST /v2/platform/auth/box_reg_keys
// 2. POST /v2/platform/boxes (with Box-Reg-Key header)
// 3. POST /v2/platform/boxes/{box_uuid}/users
// 4. POST /v2/platform/boxes/{box_uuid}/users/{user_id}/clients

// After (single step):
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

**Option B: Keep existing flow**

The existing registration flow continues to work. No changes required.

---

### For Clients (Android/iOS/Web)

**No immediate changes required.**

The client interacts with the server (space-agent), not directly with the platform. The server handles platform registration.

**Future consideration**: If implementing direct platform integration, use the new `/v2/platform/spaces` endpoint.

---

## Configuration Changes

### DNS Records (Simplified)

**Before** (7 records):
```
A  example.com          -> IP
A  services.example.com -> IP
A  *.example.com        -> IP
A  *.res.example.com    -> IP
A  *.update.example.com -> IP
A  *.download.example.com -> IP
A  *.push.example.com   -> IP
```

**After** (2 records):
```
A  example.com   -> IP
A  *.example.com -> IP
```

### SSL Certificate

**Before**: Multiple SAN entries or multiple certificates
**After**: Single wildcard certificate for `*.example.com` + `example.com`

---

## Migration Guide

### From Full Platform to Simplified

1. **Backup data**:
   ```bash
   docker exec aoplatform-mysql mysqldump -u root -p aoplatform > backup.sql
   ```

2. **Update compose file**:
   ```bash
   cd deploy/platform
   cp docker-compose.simple.yml docker-compose.yml
   cp .env.simple.example .env
   # Edit .env with your settings
   ```

3. **Restart services**:
   ```bash
   docker compose down
   docker compose up -d
   ```

4. **Reinitialize network**:
   ```bash
   ./scripts/init-network.sh
   ```

### Existing registrations remain valid

The simplified platform uses the same database schema. Existing box/user/client registrations will continue to work.

---

## API Comparison Table

| Feature | Old API | New API | Notes |
|---------|---------|---------|-------|
| Register box | POST /boxes + Box-Reg-Key | POST /spaces | No token required |
| Register user | POST /boxes/{id}/users | (included in /spaces) | Combined |
| Register client | POST /boxes/{id}/users/{id}/clients | (included in /spaces) | Combined |
| Get network creds | (in box registration response) | (in /spaces response) | Same format |
| Delete space | DELETE /boxes/{id} | DELETE /spaces/{id} | Same effect |
| Subdomain | Auto or manual | Auto or manual | Same |

---

## Error Codes

New error codes for the simplified API:

| Code | HTTP Status | Description |
|------|-------------|-------------|
| SUBDOMAIN_ALREADY_USED | 409 | Requested subdomain is taken by another box |
| SUBDOMAIN_INVALID | 400 | Subdomain format invalid |
| BOX_NOT_REGISTERED | 404 | Box not found (for GET/DELETE) |
