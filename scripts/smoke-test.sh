#!/usr/bin/env bash
# =============================================================================
# DSQL Smoke Test
# =============================================================================
set -euo pipefail

ENDPOINT="${1:-${DSQL_ENDPOINT:-}}"
REGION="${2:-${AWS_REGION:-us-east-1}}"

if [[ -z "$ENDPOINT" ]]; then
    echo "Usage: $0 <endpoint> [region]"
    echo "  or: DSQL_ENDPOINT=xxx $0"
    exit 1
fi

echo "=== DSQL Smoke Test ==="
echo "Endpoint: $ENDPOINT"
echo "Region: $REGION"
echo ""

# DNS check
echo "[1/3] DNS resolution..."
if host "$ENDPOINT" > /dev/null 2>&1; then
    echo "✓ DNS OK"
else
    echo "✗ DNS failed"
    exit 1
fi

# TCP check
echo "[2/3] TCP connectivity (port 5432)..."
if nc -z -w5 "$ENDPOINT" 5432 2>/dev/null || timeout 5 bash -c "echo > /dev/tcp/$ENDPOINT/5432" 2>/dev/null; then
    echo "✓ TCP OK"
else
    echo "✗ TCP failed"
    exit 1
fi

# DSQL auth token check
echo "[3/3] DSQL auth token generation..."
if command -v aws &> /dev/null; then
    TOKEN=$(aws dsql generate-db-connect-admin-auth-token \
        --hostname "$ENDPOINT" \
        --region "$REGION" 2>/dev/null || echo "")
    if [[ -n "$TOKEN" ]]; then
        echo "✓ Auth token generated"
        
        # Optional: test psql connection
        if command -v psql &> /dev/null; then
            echo ""
            echo "Testing psql connection..."
            if PGPASSWORD="$TOKEN" psql -h "$ENDPOINT" -p 5432 -U admin -d postgres -c "SELECT 1;" "sslmode=require" 2>/dev/null; then
                echo "✓ Database connection OK"
            else
                echo "⚠ psql connection failed (may need VPC endpoint for private access)"
            fi
        fi
    else
        echo "⚠ Could not generate auth token (check IAM permissions)"
    fi
else
    echo "⚠ AWS CLI not available, skipping auth test"
fi

echo ""
echo "=== Smoke test passed ==="
