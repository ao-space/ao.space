-- AO.Space Platform - Database Initialization
-- This script initializes the network server configuration
-- Run this after the platform services have started

-- Insert default network server (GT Server)
-- The host and port should match your deployment configuration
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
    ${GT_BIND_PORT:-61012},
    'gt-server-default',
    1,
    '{}'
) ON DUPLICATE KEY UPDATE
    server_addr = VALUES(server_addr),
    server_port = VALUES(server_port),
    state = VALUES(state);
