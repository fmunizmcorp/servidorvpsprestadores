#!/bin/bash
# Test Sprint 36 sudo fix
SITE_NAME="sprint36test$(date +%s)"

echo "=== SPRINT 36 SUDO TEST ==="
echo "Testing sudo -n execution as would be done by PHP"
echo "Site name: $SITE_NAME"
echo ""

# Copy script to /tmp
cp storage/app/post_site_creation.sh /tmp/post_site_creation.sh
chmod 755 /tmp/post_site_creation.sh

echo "Testing command: /usr/bin/sudo -n /tmp/post_site_creation.sh $SITE_NAME"
echo ""

# Test the exact command format
/usr/bin/sudo -n /tmp/post_site_creation.sh "$SITE_NAME"

echo ""
echo "Exit code: $?"
echo ""
echo "Log file contents:"
cat /tmp/post-site-${SITE_NAME}.log 2>/dev/null || echo "No log file created"
