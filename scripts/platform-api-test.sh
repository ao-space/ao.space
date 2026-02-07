#!/bin/bash

# Platform API Test Script
# Tests the simplified platform API endpoints

set -e

# Configuration
PLATFORM_BASE=${PLATFORM_BASE:-"http://127.0.0.1:8080"}
REQUEST_ID=$(uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
TOTAL=0

# Test helper functions
log_test() {
    echo -e "${YELLOW}[TEST]${NC} $1"
    TOTAL=$((TOTAL + 1))
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    PASSED=$((PASSED + 1))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    FAILED=$((FAILED + 1))
}

check_response() {
    local response="$1"
    local expected="$2"
    local message="$3"

    if echo "$response" | grep -q "$expected"; then
        log_pass "$message"
        return 0
    else
        log_fail "$message"
        echo "  Expected: $expected"
        echo "  Got: $response"
        return 1
    fi
}

check_status() {
    local http_status="$1"
    local expected="$2"
    local message="$3"

    if [ "$http_status" -eq "$expected" ]; then
        log_pass "$message"
        return 0
    else
        log_fail "$message (expected $expected, got $http_status)"
        return 1
    fi
}

# Generate test data
BOX_UUID=$(uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid)
USER_ID="test-user-$(date +%s)"
CLIENT_UUID=$(uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid)
SUBDOMAIN="test$(date +%s | tail -c 7)"

echo "============================================"
echo "Platform API Test Suite"
echo "============================================"
echo "Base URL: $PLATFORM_BASE"
echo "Box UUID: $BOX_UUID"
echo "User ID: $USER_ID"
echo "Subdomain: $SUBDOMAIN"
echo "============================================"
echo ""

# ============================================
# Test 1: Platform Status
# ============================================
log_test "GET /v2/platform/status"
response=$(curl -s -w "\n%{http_code}" \
    -H "Request-Id: $REQUEST_ID" \
    "$PLATFORM_BASE/v2/platform/status")
http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$ d')

check_status "$http_code" 200 "Status endpoint returns 200"
check_response "$body" '"status":"ok"' "Status is 'ok'"

# ============================================
# Test 2: Platform Ability
# ============================================
log_test "GET /v2/platform/ability"
response=$(curl -s -w "\n%{http_code}" \
    -H "Request-Id: $REQUEST_ID" \
    "$PLATFORM_BASE/v2/platform/ability")
http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$ d')

check_status "$http_code" 200 "Ability endpoint returns 200"
check_response "$body" "platformApis" "Contains platformApis field"

# ============================================
# Test 3: Space Registration (Simplified API)
# ============================================
log_test "POST /v2/platform/spaces"
response=$(curl -s -w "\n%{http_code}" \
    -X POST \
    -H "Content-Type: application/json" \
    -H "Request-Id: $REQUEST_ID" \
    -d "{
        \"boxUUID\": \"$BOX_UUID\",
        \"userId\": \"$USER_ID\",
        \"clientUUID\": \"$CLIENT_UUID\",
        \"subdomain\": \"$SUBDOMAIN\"
    }" \
    "$PLATFORM_BASE/v2/platform/spaces")
http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$ d')

check_status "$http_code" 200 "Space registration returns 200"
check_response "$body" '"boxUUID"' "Contains boxUUID"
check_response "$body" '"userDomain"' "Contains userDomain"
check_response "$body" '"networkClient"' "Contains networkClient"

# Extract network credentials for further tests
NETWORK_CLIENT_ID=$(echo "$body" | grep -o '"clientId":"[^"]*"' | head -1 | cut -d'"' -f4)
NETWORK_SECRET_KEY=$(echo "$body" | grep -o '"secretKey":"[^"]*"' | head -1 | cut -d'"' -f4)

echo ""
echo "Extracted credentials:"
echo "  Network Client ID: $NETWORK_CLIENT_ID"
echo "  Network Secret Key: ${NETWORK_SECRET_KEY:0:10}..."
echo ""

# ============================================
# Test 4: Network Client Auth (Valid)
# ============================================
log_test "POST /v2/platform/clients/network/auth (valid credentials)"
response=$(curl -s -w "\n%{http_code}" \
    -X POST \
    -H "Content-Type: application/json" \
    -H "Request-Id: $REQUEST_ID" \
    -d "{
        \"networkClientId\": \"$NETWORK_CLIENT_ID\",
        \"networkSecretKey\": \"$NETWORK_SECRET_KEY\"
    }" \
    "$PLATFORM_BASE/v2/platform/clients/network/auth")
http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$ d')

check_status "$http_code" 200 "Network auth returns 200"
check_response "$body" '"result":true' "Auth result is true"

# ============================================
# Test 5: Network Client Auth (Invalid)
# ============================================
log_test "POST /v2/platform/clients/network/auth (invalid credentials)"
response=$(curl -s -w "\n%{http_code}" \
    -X POST \
    -H "Content-Type: application/json" \
    -H "Request-Id: $REQUEST_ID" \
    -d "{
        \"networkClientId\": \"invalid-id\",
        \"networkSecretKey\": \"invalid-key\"
    }" \
    "$PLATFORM_BASE/v2/platform/clients/network/auth")
http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$ d')

check_status "$http_code" 200 "Network auth returns 200"
check_response "$body" '"result":false' "Auth result is false"

# ============================================
# Test 6: Get Space Info
# ============================================
log_test "GET /v2/platform/spaces/{box_uuid}"
response=$(curl -s -w "\n%{http_code}" \
    -H "Request-Id: $REQUEST_ID" \
    "$PLATFORM_BASE/v2/platform/spaces/$BOX_UUID")
http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$ d')

check_status "$http_code" 200 "Get space returns 200"
check_response "$body" '"networkClientId"' "Contains networkClientId"

# ============================================
# Test 7: Network Server Detail
# ============================================
log_test "GET /v2/platform/servers/network/detail"
response=$(curl -s -w "\n%{http_code}" \
    -H "Request-Id: $REQUEST_ID" \
    "$PLATFORM_BASE/v2/platform/servers/network/detail?network_client_id=$NETWORK_CLIENT_ID")
http_code=$(echo "$response" | tail -1)

check_status "$http_code" 200 "Network server detail returns 200"

# ============================================
# Test 8: STUN Server Detail
# ============================================
log_test "GET /v2/platform/servers/stun/detail"
response=$(curl -s -w "\n%{http_code}" \
    -H "Request-Id: $REQUEST_ID" \
    "$PLATFORM_BASE/v2/platform/servers/stun/detail?subdomain=$SUBDOMAIN")
http_code=$(echo "$response" | tail -1)

check_status "$http_code" 200 "STUN server detail returns 200"

# ============================================
# Test 9: Duplicate Space Registration (Same Box, Different User)
# ============================================
log_test "POST /v2/platform/spaces (same box, different user)"
USER_ID_2="test-user2-$(date +%s)"
CLIENT_UUID_2=$(uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid)
response=$(curl -s -w "\n%{http_code}" \
    -X POST \
    -H "Content-Type: application/json" \
    -H "Request-Id: $REQUEST_ID" \
    -d "{
        \"boxUUID\": \"$BOX_UUID\",
        \"userId\": \"$USER_ID_2\",
        \"clientUUID\": \"$CLIENT_UUID_2\"
    }" \
    "$PLATFORM_BASE/v2/platform/spaces")
http_code=$(echo "$response" | tail -1)
body=$(echo "$response" | sed '$ d')

check_status "$http_code" 200 "Second user registration returns 200"
# Should reuse the same network client
check_response "$body" "\"clientId\":\"$NETWORK_CLIENT_ID\"" "Reuses same network client ID"

# ============================================
# Test 10: Delete Space
# ============================================
log_test "DELETE /v2/platform/spaces/{box_uuid}"
response=$(curl -s -w "\n%{http_code}" \
    -X DELETE \
    -H "Request-Id: $REQUEST_ID" \
    "$PLATFORM_BASE/v2/platform/spaces/$BOX_UUID")
http_code=$(echo "$response" | tail -1)

check_status "$http_code" 204 "Delete space returns 204"

# ============================================
# Test 11: Get Deleted Space (should fail)
# ============================================
log_test "GET /v2/platform/spaces/{box_uuid} (after deletion)"
response=$(curl -s -w "\n%{http_code}" \
    -H "Request-Id: $REQUEST_ID" \
    "$PLATFORM_BASE/v2/platform/spaces/$BOX_UUID")
http_code=$(echo "$response" | tail -1)

check_status "$http_code" 400 "Get deleted space returns 400 (not found)"

# ============================================
# Summary
# ============================================
echo ""
echo "============================================"
echo "Test Summary"
echo "============================================"
echo -e "Total:  $TOTAL"
echo -e "Passed: ${GREEN}$PASSED${NC}"
echo -e "Failed: ${RED}$FAILED${NC}"
echo "============================================"

if [ "$FAILED" -gt 0 ]; then
    exit 1
fi
