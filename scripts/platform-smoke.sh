#!/bin/bash

# Platform Smoke Test
# Quick health check for platform services

set -e

PLATFORM_BASE=${PLATFORM_BASE:-"http://127.0.0.1:8080"}

echo "Platform Smoke Test"
echo "==================="
echo "Base URL: $PLATFORM_BASE"
echo ""

# Test 1: Status endpoint
echo -n "Checking /v2/platform/status... "
status=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Request-Id: smoke-test" \
    "$PLATFORM_BASE/v2/platform/status")

if [ "$status" -eq 200 ]; then
    echo "OK"
else
    echo "FAILED (HTTP $status)"
    exit 1
fi

# Test 2: Ability endpoint
echo -n "Checking /v2/platform/ability... "
status=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Request-Id: smoke-test" \
    "$PLATFORM_BASE/v2/platform/ability")

if [ "$status" -eq 200 ]; then
    echo "OK"
else
    echo "FAILED (HTTP $status)"
    exit 1
fi

# Test 3: Swagger UI (if available)
echo -n "Checking Swagger UI... "
status=$(curl -s -o /dev/null -w "%{http_code}" \
    "$PLATFORM_BASE/platform/q/swagger-ui/")

if [ "$status" -eq 200 ]; then
    echo "OK"
else
    echo "SKIPPED (HTTP $status)"
fi

echo ""
echo "All smoke tests passed!"
