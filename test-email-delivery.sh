#!/bin/bash

#############################################################################
# TEST-EMAIL-DELIVERY.SH - Email Deliverability Tester
# Verifica DNS, SPF, DKIM, DMARC, RBLs, envia email de teste
#############################################################################

# Configuration
DOMAIN="${1:-$(hostname -d)}"
SERVER_IP="${2:-$(curl -s ifconfig.me)}"
LOG_FILE="/var/log/webserver/email-delivery-test.log"
REPORT_FILE="/tmp/email-delivery-report-$(date +%Y%m%d_%H%M%S).txt"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to log
log_message() {
    echo "[$TIMESTAMP] $1" | tee -a "$LOG_FILE"
}

# Function to print test result
print_result() {
    local test_name="$1"
    local status="$2"
    local message="$3"
    
    if [ "$status" = "PASS" ]; then
        echo -e "${GREEN}✓${NC} $test_name: PASS - $message"
    elif [ "$status" = "FAIL" ]; then
        echo -e "${RED}✗${NC} $test_name: FAIL - $message"
    else
        echo -e "${YELLOW}⚠${NC} $test_name: WARNING - $message"
    fi
    
    echo "$test_name: $status - $message" >> "$REPORT_FILE"
}

log_message "=== STARTING EMAIL DELIVERABILITY TEST ==="
log_message "Domain: $DOMAIN"
log_message "Server IP: $SERVER_IP"

echo ""
echo "========================================="
echo "  EMAIL DELIVERABILITY TEST"
echo "========================================="
echo "Domain: $DOMAIN"
echo "Server IP: $SERVER_IP"
echo ""

# Test 1: DNS A Record
echo "[1/10] Testing DNS A Record..."
A_RECORD=$(dig +short A "$DOMAIN" 2>/dev/null | head -1)

if [ -n "$A_RECORD" ]; then
    print_result "DNS A Record" "PASS" "$DOMAIN resolves to $A_RECORD"
else
    print_result "DNS A Record" "FAIL" "$DOMAIN does not resolve"
fi

# Test 2: DNS MX Record
echo "[2/10] Testing DNS MX Record..."
MX_RECORD=$(dig +short MX "$DOMAIN" 2>/dev/null | head -1)

if [ -n "$MX_RECORD" ]; then
    MX_HOST=$(echo "$MX_RECORD" | awk '{print $2}' | sed 's/\.$//')
    print_result "DNS MX Record" "PASS" "MX: $MX_RECORD"
else
    print_result "DNS MX Record" "FAIL" "No MX record found"
fi

# Test 3: Reverse DNS (PTR)
echo "[3/10] Testing Reverse DNS (PTR)..."
PTR_RECORD=$(dig +short -x "$SERVER_IP" 2>/dev/null | sed 's/\.$//')

if [ -n "$PTR_RECORD" ]; then
    if [[ "$PTR_RECORD" == *"$DOMAIN"* ]]; then
        print_result "Reverse DNS" "PASS" "PTR: $PTR_RECORD"
    else
        print_result "Reverse DNS" "WARNING" "PTR exists but doesn't match domain: $PTR_RECORD"
    fi
else
    print_result "Reverse DNS" "FAIL" "No PTR record found for $SERVER_IP"
fi

# Test 4: SPF Record
echo "[4/10] Testing SPF Record..."
SPF_RECORD=$(dig +short TXT "$DOMAIN" 2>/dev/null | grep "v=spf1")

if [ -n "$SPF_RECORD" ]; then
    print_result "SPF Record" "PASS" "$SPF_RECORD"
else
    print_result "SPF Record" "FAIL" "No SPF record found"
fi

# Test 5: DKIM Record
echo "[5/10] Testing DKIM Record..."
DKIM_SELECTOR="mail"
DKIM_RECORD=$(dig +short TXT "${DKIM_SELECTOR}._domainkey.${DOMAIN}" 2>/dev/null | grep "v=DKIM1")

if [ -n "$DKIM_RECORD" ]; then
    print_result "DKIM Record" "PASS" "DKIM record found for selector: $DKIM_SELECTOR"
else
    print_result "DKIM Record" "WARNING" "No DKIM record found for selector: $DKIM_SELECTOR"
fi

# Test 6: DMARC Record
echo "[6/10] Testing DMARC Record..."
DMARC_RECORD=$(dig +short TXT "_dmarc.${DOMAIN}" 2>/dev/null | grep "v=DMARC1")

if [ -n "$DMARC_RECORD" ]; then
    print_result "DMARC Record" "PASS" "$DMARC_RECORD"
else
    print_result "DMARC Record" "WARNING" "No DMARC record found"
fi

# Test 7: Check RBLs (Real-time Blackhole Lists)
echo "[7/10] Checking RBLs..."
RBLS=("zen.spamhaus.org" "bl.spamcop.net" "dnsbl.sorbs.net" "cbl.abuseat.org")
BLACKLISTED=false

for rbl in "${RBLS[@]}"; do
    REVERSED_IP=$(echo "$SERVER_IP" | awk -F. '{print $4"."$3"."$2"."$1}')
    LOOKUP="${REVERSED_IP}.${rbl}"
    
    if dig +short A "$LOOKUP" 2>/dev/null | grep -q "127.0.0"; then
        print_result "RBL Check" "FAIL" "IP is blacklisted in $rbl"
        BLACKLISTED=true
    fi
done

if [ "$BLACKLISTED" = false ]; then
    print_result "RBL Check" "PASS" "IP not found in major blacklists"
fi

# Test 8: SMTP Connection
echo "[8/10] Testing SMTP Connection..."
if command -v nc &> /dev/null; then
    SMTP_TEST=$(echo "QUIT" | nc -w 5 localhost 25 2>&1 | head -1)
    
    if [[ "$SMTP_TEST" == *"220"* ]]; then
        print_result "SMTP Connection" "PASS" "$SMTP_TEST"
    else
        print_result "SMTP Connection" "FAIL" "Cannot connect to SMTP"
    fi
else
    print_result "SMTP Connection" "WARNING" "nc not available for testing"
fi

# Test 9: TLS/SSL Certificate
echo "[9/10] Testing TLS/SSL..."
if command -v openssl &> /dev/null; then
    TLS_TEST=$(echo "QUIT" | timeout 5 openssl s_client -starttls smtp -connect localhost:587 -quiet 2>&1 | grep -i "Verification")
    
    if [[ "$TLS_TEST" == *"OK"* ]]; then
        print_result "TLS/SSL" "PASS" "TLS working correctly"
    else
        print_result "TLS/SSL" "WARNING" "TLS verification issue"
    fi
else
    print_result "TLS/SSL" "WARNING" "openssl not available for testing"
fi

# Test 10: Send Test Email
echo "[10/10] Sending Test Email..."
TEST_EMAIL="test@gmail.com"

if command -v sendmail &> /dev/null; then
    cat << EMAILEOF | sendmail -t
From: test@$DOMAIN
To: $TEST_EMAIL
Subject: Email Deliverability Test - $TIMESTAMP

This is an automated test email from $DOMAIN.
Server IP: $SERVER_IP
Timestamp: $TIMESTAMP

If you receive this, email delivery is working correctly.
EMAILEOF

    if [ $? -eq 0 ]; then
        print_result "Test Email" "PASS" "Test email sent to $TEST_EMAIL"
    else
        print_result "Test Email" "FAIL" "Failed to send test email"
    fi
else
    print_result "Test Email" "WARNING" "sendmail not available"
fi

# Generate Summary
echo ""
echo "========================================="
echo "  TEST SUMMARY"
echo "========================================="

PASS_COUNT=$(grep -c "PASS" "$REPORT_FILE")
FAIL_COUNT=$(grep -c "FAIL" "$REPORT_FILE")
WARN_COUNT=$(grep -c "WARNING" "$REPORT_FILE")

echo "Tests Passed: $PASS_COUNT"
echo "Tests Failed: $FAIL_COUNT"
echo "Warnings: $WARN_COUNT"
echo ""
echo "Detailed report: $REPORT_FILE"
echo ""

# Generate JSON Report
JSON_REPORT="/var/log/webserver/email-delivery-test-latest.json"
cat > "$JSON_REPORT" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "domain": "$DOMAIN",
  "server_ip": "$SERVER_IP",
  "tests": {
    "dns_a": "$([ -n "$A_RECORD" ] && echo 'pass' || echo 'fail')",
    "dns_mx": "$([ -n "$MX_RECORD" ] && echo 'pass' || echo 'fail')",
    "reverse_dns": "$([ -n "$PTR_RECORD" ] && echo 'pass' || echo 'fail')",
    "spf": "$([ -n "$SPF_RECORD" ] && echo 'pass' || echo 'fail')",
    "dkim": "$([ -n "$DKIM_RECORD" ] && echo 'pass' || echo 'warning')",
    "dmarc": "$([ -n "$DMARC_RECORD" ] && echo 'pass' || echo 'warning')",
    "rbl_check": "$([ $BLACKLISTED = false ] && echo 'pass' || echo 'fail')"
  },
  "summary": {
    "pass_count": ${PASS_COUNT},
    "fail_count": ${FAIL_COUNT},
    "warn_count": ${WARN_COUNT}
  },
  "report_file": "$REPORT_FILE"
}
EOF

log_message "=== EMAIL DELIVERABILITY TEST COMPLETE ==="

exit 0