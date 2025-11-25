#!/bin/bash

# Try to read files from production server via SSH
# If SSH fails, we'll create a diagnostic script

echo "Attempting to read production files..."
echo ""

# Method 1: Try direct SSH
ssh -o StrictHostKeyChecking=no -o BatchMode=yes root@72.61.53.222 'cat /opt/webserver/admin-panel/routes/web.php' > routes_web_CURRENT_PROD.php 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Successfully read web.php from production"
    wc -l routes_web_CURRENT_PROD.php
else
    echo "❌ SSH authentication failed"
    echo "Cannot access production files directly"
    echo ""
    echo "ANALYSIS BASED ON QA REPORT:"
    echo "=============================="
    echo ""
    echo "QA Report shows:"
    echo "1. Session is lost when creating sites"
    echo "2. No data persisted to database"
    echo "3. No directories created"
    echo ""
    echo "This suggests the problem is NOT just routing."
    echo "The problem is likely in:"
    echo "- Session middleware configuration"
    echo "- CSRF token handling after my route changes"
    echo "- Form submission not reaching controller"
    echo ""
fi

