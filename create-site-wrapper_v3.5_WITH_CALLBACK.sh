#!/bin/bash

###############################################################################
# SPRINT57 v3.5: Site Creation Wrapper Script with Callback
# 
# This script executes in BACKGROUND and calls back to Laravel when complete
###############################################################################

set -e  # Exit on error

# Parse arguments
SITE_NAME="$1"
DOMAIN="$2"
PHP_VERSION="$3"
CREATE_DB="yes"
TEMPLATE="php"
CALLBACK_URL=""
SITE_ID=""

# Parse optional flags
shift 3
while [[ $# -gt 0 ]]; do
    case $1 in
        --no-db)
            CREATE_DB="no"
            shift
            ;;
        --template=*)
            TEMPLATE="${1#*=}"
            shift
            ;;
        --callback-url=*)
            CALLBACK_URL="${1#*=}"
            shift
            ;;
        --site-id=*)
            SITE_ID="${1#*=}"
            shift
            ;;
        *)
            shift
            ;;
    esac
done

echo "========================================="
echo "SPRINT57 v3.5: Site Creation Started"
echo "========================================="
echo "Site: $SITE_NAME"
echo "Domain: $DOMAIN"
echo "PHP Version: $PHP_VERSION"
echo "Create Database: $CREATE_DB"
echo "Template: $TEMPLATE"
echo "Callback URL: $CALLBACK_URL"
echo "Site ID: $SITE_ID"
echo "========================================="
echo ""

# Function to send callback
send_callback() {
    local status="$1"
    local error="$2"
    
    if [ -n "$CALLBACK_URL" ] && [ -n "$SITE_ID" ]; then
        echo "Sending callback to $CALLBACK_URL..."
        
        curl -X POST "$CALLBACK_URL" \
            -H "Content-Type: application/json" \
            -d "{\"site_id\":$SITE_ID,\"site_name\":\"$SITE_NAME\",\"status\":\"$status\",\"error\":\"$error\"}" \
            --max-time 5 \
            --silent \
            --show-error \
            || echo "Warning: Callback failed, but continuing..."
    fi
}

# Trap errors and send failure callback
trap 'send_callback "failed" "Script execution failed at line $LINENO"' ERR

# Call the actual create-site.sh script
ACTUAL_SCRIPT="/opt/webserver/scripts/create-site.sh"

if [ ! -f "$ACTUAL_SCRIPT" ]; then
    echo "ERROR: Actual script not found: $ACTUAL_SCRIPT"
    send_callback "failed" "Create site script not found"
    exit 1
fi

# Execute the actual creation script
if [ "$CREATE_DB" = "yes" ]; then
    bash "$ACTUAL_SCRIPT" "$SITE_NAME" "$DOMAIN" "$PHP_VERSION" --template="$TEMPLATE"
else
    bash "$ACTUAL_SCRIPT" "$SITE_NAME" "$DOMAIN" "$PHP_VERSION" --no-db --template="$TEMPLATE"
fi

RESULT=$?

echo ""
echo "========================================="
if [ $RESULT -eq 0 ]; then
    echo "✓ Site creation completed successfully!"
    send_callback "active" ""
else
    echo "✗ Site creation failed with exit code: $RESULT"
    send_callback "failed" "Script exited with code $RESULT"
fi
echo "========================================="

exit $RESULT
