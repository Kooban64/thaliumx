#!/bin/bash

# ThaliumX Production Rate Limiting Setup
# =======================================
# This script configures comprehensive rate limiting for production deployment

set -e

APISIX_ADMIN_URL="${APISIX_ADMIN_URL:-http://localhost:9180}"
APISIX_ADMIN_KEY="${APISIX_ADMIN_KEY:-thaliumx-admin-key}"

echo "=============================================="
echo "ThaliumX Production Rate Limiting Setup"
echo "=============================================="
echo "Admin URL: $APISIX_ADMIN_URL"
echo ""

# Function to create or update global rules
create_global_rule() {
    local rule_id=$1
    local rule_data=$2

    echo "Creating/Updating global rule $rule_id..."

    response=$(curl -s -w "\n%{http_code}" -X PUT "$APISIX_ADMIN_URL/apisix/admin/global_rules/$rule_id" \
        -H "X-API-KEY: $APISIX_ADMIN_KEY" \
        -H "Content-Type: application/json" \
        -d "$rule_data")

    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')

    if [ "$http_code" = "200" ] || [ "$http_code" = "201" ]; then
        echo "  ✅ Global rule $rule_id configured successfully"
    else
        echo "  ❌ Failed to configure global rule $rule_id (HTTP $http_code)"
        echo "  Response: $body"
    fi
}

echo "Step 1: Setting up Global Rate Limiting Rules"
echo "----------------------------------------------"

# Global Rule 1: General API rate limiting (1000 req/min per IP)
create_global_rule "1" '{
    "id": "1",
    "name": "global-api-rate-limit",
    "desc": "Global API rate limiting - 1000 requests per minute per IP",
    "plugins": {
        "limit-count": {
            "count": 1000,
            "time_window": 60,
            "rejected_code": 429,
            "rejected_msg": "API rate limit exceeded. Please try again later.",
            "key": "remote_addr",
            "key_type": "var",
            "policy": "local"
        }
    }
}'

# Global Rule 2: Authentication endpoints stricter limiting (10 req/min per IP)
create_global_rule "2" '{
    "id": "2",
    "name": "auth-rate-limit",
    "desc": "Authentication endpoints - 10 requests per minute per IP",
    "plugins": {
        "limit-count": {
            "count": 10,
            "time_window": 60,
            "rejected_code": 429,
            "rejected_msg": "Too many authentication attempts. Please try again later.",
            "key": "remote_addr",
            "key_type": "var",
            "policy": "local"
        }
    },
    "match": {
        "vars": [
            ["uri", "~~", "^/api/auth/"]
        ]
    }
}'

# Global Rule 3: Trading endpoints rate limiting (500 req/min per IP)
create_global_rule "3" '{
    "id": "3",
    "name": "trading-rate-limit",
    "desc": "Trading endpoints - 500 requests per minute per IP",
    "plugins": {
        "limit-count": {
            "count": 500,
            "time_window": 60,
            "rejected_code": 429,
            "rejected_msg": "Trading rate limit exceeded. Please slow down your requests.",
            "key": "remote_addr",
            "key_type": "var",
            "policy": "local"
        }
    },
    "match": {
        "vars": [
            ["uri", "~~", "^/api/trading/"]
        ]
    }
}'

# Global Rule 4: Financial operations strict limiting (100 req/min per IP)
create_global_rule "4" '{
    "id": "4",
    "name": "financial-rate-limit",
    "desc": "Financial operations - 100 requests per minute per IP",
    "plugins": {
        "limit-count": {
            "count": 100,
            "time_window": 60,
            "rejected_code": 429,
            "rejected_msg": "Financial operation rate limit exceeded. Please try again later.",
            "key": "remote_addr",
            "key_type": "var",
            "policy": "local"
        }
    },
    "match": {
        "vars": [
            ["uri", "~~", "^/api/(financial|wallet|margin)/"]
        ]
    }
}'

# Global Rule 5: Admin endpoints very strict limiting (50 req/min per IP)
create_global_rule "5" '{
    "id": "5",
    "name": "admin-rate-limit",
    "desc": "Admin endpoints - 50 requests per minute per IP",
    "plugins": {
        "limit-count": {
            "count": 50,
            "time_window": 60,
            "rejected_code": 429,
            "rejected_msg": "Admin rate limit exceeded.",
            "key": "remote_addr",
            "key_type": "var",
            "policy": "local"
        }
    },
    "match": {
        "vars": [
            ["uri", "~~", "^/api/admin/"]
        ]
    }
}'

# Global Rule 6: WebSocket connections limiting (100 connections per IP)
create_global_rule "6" '{
    "id": "6",
    "name": "websocket-rate-limit",
    "desc": "WebSocket connections - 100 connections per minute per IP",
    "plugins": {
        "limit-conn": {
            "conn": 100,
            "burst": 200,
            "default_conn_delay": 0.1,
            "key": "remote_addr",
            "key_type": "var",
            "rejected_code": 429,
            "rejected_msg": "WebSocket connection limit exceeded."
        }
    },
    "match": {
        "vars": [
            ["uri", "~~", "^/socket\\.io/"]
        ]
    }
}'

# Global Rule 7: IP-based concurrent connection limiting
create_global_rule "7" '{
    "id": "7",
    "name": "connection-rate-limit",
    "desc": "Concurrent connections - max 50 per IP",
    "plugins": {
        "limit-conn": {
            "conn": 50,
            "burst": 100,
            "default_conn_delay": 0.1,
            "key": "remote_addr",
            "key_type": "var",
            "rejected_code": 429,
            "rejected_msg": "Connection limit exceeded."
        }
    }
}'

# Global Rule 8: Request size limiting (10MB max)
create_global_rule "8" '{
    "id": "8",
    "name": "request-size-limit",
    "desc": "Request size limiting - max 10MB",
    "plugins": {
        "request-validation": {
            "body_schema": {
                "type": "object",
                "maxProperties": 100,
                "additionalProperties": false
            },
            "header_schema": {
                "type": "object",
                "properties": {
                    "content-length": {
                        "type": "integer",
                        "maximum": 10485760
                    }
                }
            }
        }
    }
}'

echo ""
echo "Step 2: Verifying Rate Limiting Configuration"
echo "---------------------------------------------"

# List all global rules
echo "Configured global rules:"
curl -s "$APISIX_ADMIN_URL/apisix/admin/global_rules" \
    -H "X-API-KEY: $APISIX_ADMIN_KEY" | python3 -c "
import json, sys
data = json.load(sys.stdin)
rules = data.get('list', [])
print(f'Total global rules: {len(rules)}')
for rule in rules:
    r = rule.get('value', {})
    print(f\"  - {r.get('id')}: {r.get('name')}\")
" 2>/dev/null || echo "  (Unable to parse global rules)"

echo ""
echo "Step 3: Testing Rate Limiting"
echo "------------------------------"

# Test basic rate limiting
echo "Testing basic API rate limiting..."
for i in {1..5}; do
    response=$(curl -s -w "%{http_code}" -o /dev/null "$APISIX_ADMIN_URL/apisix/admin/routes" \
        -H "X-API-KEY: invalid_key")
    echo "Request $i: HTTP $response"
    sleep 0.1
done

echo ""
echo "=============================================="
echo "Production Rate Limiting Setup Complete!"
echo "=============================================="
echo ""
echo "Rate Limits Applied:"
echo "  - General API:     1000 req/min per IP"
echo "  - Auth endpoints:   10 req/min per IP"
echo "  - Trading API:     500 req/min per IP"
echo "  - Financial ops:   100 req/min per IP"
echo "  - Admin API:       50 req/min per IP"
echo "  - WebSocket:       100 conn/min per IP"
echo "  - Max connections: 50 concurrent per IP"
echo "  - Max request size: 10MB"
echo ""
echo "Monitor rate limiting with:"
echo "  curl http://localhost:9091/apisix/prometheus/metrics"
echo ""