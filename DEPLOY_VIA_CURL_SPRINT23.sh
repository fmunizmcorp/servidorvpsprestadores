#!/bin/bash

###############################################################################
# SPRINT 23 - Web-Based Deployment via cURL
# 
# This script executes the deployment by calling the web-based deployment
# endpoint. No SSH access required!
#
# PREREQUISITES:
# 1. Upload DeployController_SPRINT23.php to VPS at:
#    /opt/webserver/admin-panel/app/Http/Controllers/DeployController.php
# 
# 2. Add routes to /opt/webserver/admin-panel/routes/web.php:
#    (see deploy_routes_SPRINT23.php)
#
# 3. Create view at /opt/webserver/admin-panel/resources/views/deploy/index.blade.php
#    (see deploy_index_blade_SPRINT23.php)
#
# USAGE:
#   bash DEPLOY_VIA_CURL_SPRINT23.sh
#
###############################################################################

set -e

echo "========================================="
echo "SPRINT 23 - Web-Based Deployment"
echo "========================================="
echo ""

# Configuration
VPS_IP="72.61.53.222"
ADMIN_URL="http://${VPS_IP}/admin"
DEPLOY_URL="${ADMIN_URL}/deploy/execute"
STATUS_URL="${ADMIN_URL}/deploy/status"
SECRET="sprint23deploy"

# Credentials
USERNAME="test@admin.local"
PASSWORD="Test@123456"

echo "📋 Step 1: Testing VPS connectivity..."
if ! curl -s -o /dev/null -w "%{http_code}" "http://${VPS_IP}/admin" | grep -q "200\|302"; then
    echo "❌ ERROR: Cannot reach VPS at ${VPS_IP}"
    echo "   Please verify VPS is running and accessible"
    exit 1
fi
echo "✅ VPS is accessible"
echo ""

echo "📋 Step 2: Authenticating to admin panel..."
# Create cookie jar
COOKIE_FILE="/tmp/sprint23_cookies.txt"
rm -f "$COOKIE_FILE"

# Get login page and CSRF token
LOGIN_PAGE=$(curl -s -c "$COOKIE_FILE" "${ADMIN_URL}/login")
CSRF_TOKEN=$(echo "$LOGIN_PAGE" | grep -oP 'name="_token" value="\K[^"]+' || echo "")

if [ -z "$CSRF_TOKEN" ]; then
    echo "⚠️  Warning: Could not extract CSRF token from login page"
    echo "   Attempting deployment without authentication..."
else
    # Perform login
    curl -s -b "$COOKIE_FILE" -c "$COOKIE_FILE" \
        -d "_token=${CSRF_TOKEN}" \
        -d "email=${USERNAME}" \
        -d "password=${PASSWORD}" \
        "${ADMIN_URL}/login" > /dev/null
    
    echo "✅ Authentication attempted (check cookies)"
fi
echo ""

echo "📋 Step 3: Checking current deployment status..."
STATUS_RESPONSE=$(curl -s -b "$COOKIE_FILE" "${STATUS_URL}")

if echo "$STATUS_RESPONSE" | grep -q "overall_status"; then
    echo "✅ Status endpoint accessible"
    echo ""
    echo "Current Status:"
    echo "$STATUS_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$STATUS_RESPONSE"
else
    echo "⚠️  Warning: Could not access status endpoint"
    echo "   Response: $STATUS_RESPONSE"
fi
echo ""

echo "📋 Step 4: Executing deployment..."
echo "   URL: ${DEPLOY_URL}?secret=${SECRET}"
echo ""

DEPLOY_RESPONSE=$(curl -s -b "$COOKIE_FILE" "${DEPLOY_URL}?secret=${SECRET}")

echo "========================================="
echo "DEPLOYMENT RESULTS"
echo "========================================="
echo ""

# Try to pretty-print JSON
if echo "$DEPLOY_RESPONSE" | grep -q '"success"'; then
    echo "$DEPLOY_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$DEPLOY_RESPONSE"
    
    # Check if successful
    if echo "$DEPLOY_RESPONSE" | grep -q '"success": *true'; then
        echo ""
        echo "========================================="
        echo "✅ DEPLOYMENT SUCCESSFUL!"
        echo "========================================="
        echo ""
        echo "📋 Next Steps:"
        echo "1. Test Email Domain creation: ${ADMIN_URL}/email/domains"
        echo "2. Test Email Account creation: ${ADMIN_URL}/email/accounts"
        echo "3. Test Site creation: ${ADMIN_URL}/sites/create"
        echo ""
        echo "4. Verify persistence on VPS:"
        echo "   - SSH to VPS: ssh root@${VPS_IP}"
        echo "   - Check domains: grep 'test' /etc/postfix/virtual_domains"
        echo "   - Check accounts: grep 'test' /etc/postfix/virtual_mailbox_maps"
        echo "   - Check sites: ls -la /opt/webserver/sites/"
        echo ""
        exit 0
    else
        echo ""
        echo "========================================="
        echo "❌ DEPLOYMENT FAILED"
        echo "========================================="
        echo ""
        echo "Please review the error messages above."
        echo ""
        exit 1
    fi
else
    echo "❌ Unexpected response from deployment endpoint:"
    echo "$DEPLOY_RESPONSE"
    echo ""
    echo "Possible causes:"
    echo "1. DeployController.php not uploaded to VPS"
    echo "2. Routes not added to web.php"
    echo "3. Authentication failed"
    echo "4. Invalid secret key"
    echo ""
    exit 1
fi

# Cleanup
rm -f "$COOKIE_FILE"
