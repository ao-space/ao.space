#!/bin/bash

# Initialize network server configuration
# Run this after docker compose up

set -e

# Load environment
if [ -f .env ]; then
    source .env
else
    echo "Error: .env file not found"
    exit 1
fi

# Default values
GT_BIND_PORT=${GT_BIND_PORT:-61012}
MYSQL_DATABASE=${MYSQL_DATABASE:-aoplatform}
MYSQL_USER=${MYSQL_USER:-aoplatform}

echo "Initializing network server configuration..."
echo "  Domain: ${USER_DOMAIN}"
echo "  GT Port: ${GT_BIND_PORT}"

# Wait for MySQL to be ready
echo "Waiting for MySQL..."
until docker exec aoplatform-mysql mysqladmin ping -h 127.0.0.1 -u${MYSQL_USER} -p${MYSQL_PASSWORD} --silent 2>/dev/null; do
    sleep 2
done

# Insert or update network server info
docker exec -i aoplatform-mysql mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} << EOF
INSERT INTO network_server_info (
    server_protocol,
    server_addr,
    server_port,
    identifier,
    state,
    extra
) VALUES (
    'https',
    '${USER_DOMAIN}',
    ${GT_BIND_PORT},
    'gt-server-default',
    1,
    '{}'
) ON DUPLICATE KEY UPDATE
    server_addr = '${USER_DOMAIN}',
    server_port = ${GT_BIND_PORT},
    state = 1;
EOF

echo "Network server configuration initialized successfully!"
echo ""
echo "Platform is ready at:"
echo "  - API: https://${USER_DOMAIN}/v2/platform/status"
echo "  - Swagger: https://${USER_DOMAIN}/platform/q/swagger-ui"
