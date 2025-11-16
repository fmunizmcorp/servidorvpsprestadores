#!/bin/bash

#############################################################################
# ANALYZE-MAIL-LOGS.SH - Mail Log Analyzer
# Análise completa de /var/log/mail.log
#############################################################################

# Configuration
MAIL_LOG="/var/log/mail.log"
LOG_FILE="/var/log/webserver/mail-analysis.log"
REPORT_DIR="/var/log/webserver/reports"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
REPORT_DATE=$(date '+%Y-%m-%d')
ANALYSIS_PERIOD="${1:-today}" # today, week, month

# Create directories
mkdir -p "$REPORT_DIR"
mkdir -p /var/log/webserver

# Function to log
log_message() {
    echo "[$TIMESTAMP] $1" | tee -a "$LOG_FILE"
}

# Get date filter based on period
get_date_filter() {
    case $ANALYSIS_PERIOD in
        today)
            echo "$(date +%b\ %d)"
            ;;
        week)
            echo "$(date -d '7 days ago' +%b\ %d)"
            ;;
        month)
            echo "$(date -d '30 days ago' +%b\ %d)"
            ;;
        *)
            echo "$(date +%b\ %d)"
            ;;
    esac
}

log_message "=== STARTING MAIL LOG ANALYSIS ==="
log_message "Analysis period: $ANALYSIS_PERIOD"

DATE_FILTER=$(get_date_filter)

# Count sent emails
SENT_COUNT=$(grep "$DATE_FILTER" "$MAIL_LOG" 2>/dev/null | grep -c "status=sent" || echo "0")
log_message "Sent emails: $SENT_COUNT"

# Count received emails
RECEIVED_COUNT=$(grep "$DATE_FILTER" "$MAIL_LOG" 2>/dev/null | grep -c "from=<.*>, to=<" || echo "0")
log_message "Received emails: $RECEIVED_COUNT"

# Count bounced emails
BOUNCED_COUNT=$(grep "$DATE_FILTER" "$MAIL_LOG" 2>/dev/null | grep -c "status=bounced" || echo "0")
log_message "Bounced emails: $BOUNCED_COUNT"

# Count deferred emails
DEFERRED_COUNT=$(grep "$DATE_FILTER" "$MAIL_LOG" 2>/dev/null | grep -c "status=deferred" || echo "0")
log_message "Deferred emails: $DEFERRED_COUNT"

# Count rejected emails
REJECTED_COUNT=$(grep "$DATE_FILTER" "$MAIL_LOG" 2>/dev/null | grep -c "reject" || echo "0")
log_message "Rejected emails: $REJECTED_COUNT"

# Calculate bounce rate
if [ "$SENT_COUNT" -gt 0 ]; then
    BOUNCE_RATE=$(awk "BEGIN {printf \"%.2f\", ($BOUNCED_COUNT / $SENT_COUNT) * 100}")
else
    BOUNCE_RATE="0.00"
fi
log_message "Bounce rate: ${BOUNCE_RATE}%"

# Top 10 senders
log_message "Analyzing top senders..."
TOP_SENDERS=$(grep "$DATE_FILTER" "$MAIL_LOG" 2>/dev/null | grep "from=<" | sed -n 's/.*from=<\\([^>]*\\)>.*/\\1/p' | sort | uniq -c | sort -rn | head -10)

# Top 10 recipients
log_message "Analyzing top recipients..."
TOP_RECIPIENTS=$(grep "$DATE_FILTER" "$MAIL_LOG" 2>/dev/null | grep "to=<" | sed -n 's/.*to=<\\([^>]*\\)>.*/\\1/p' | sort | uniq -c | sort -rn | head -10)

# Top 10 external domains
log_message "Analyzing top external domains..."
TOP_DOMAINS=$(grep "$DATE_FILTER" "$MAIL_LOG" 2>/dev/null | grep -oE 'to=<[^@]+@([^>]+)>' | sed 's/to=<[^@]*@//;s/>//' | sort | uniq -c | sort -rn | head -10)

# Rejection reasons
log_message "Analyzing rejection reasons..."
REJECTION_REASONS=$(grep "$DATE_FILTER" "$MAIL_LOG" 2>/dev/null | grep "reject:" | sed 's/.*reject: //' | cut -d';' -f1 | sort | uniq -c | sort -rn | head -10)

# Spam blocked
SPAM_BLOCKED=$(grep "$DATE_FILTER" "$MAIL_LOG" 2>/dev/null | grep -ic "spam" || echo "0")
log_message "Spam blocked: $SPAM_BLOCKED"

# Average delivery time
log_message "Calculating average delivery time..."
AVG_DELAY="N/A"

DELAYS=$(grep "$DATE_FILTER" "$MAIL_LOG" 2>/dev/null | grep "delay=" | sed -n 's/.*delay=\\([0-9.]*\\).*/\\1/p')
if [ -n "$DELAYS" ]; then
    AVG_DELAY=$(echo "$DELAYS" | awk '{sum+=$1; count++} END {if(count>0) printf "%.2f", sum/count; else print "0"}')
    log_message "Average delivery delay: ${AVG_DELAY}s"
fi

# Connection errors
CONNECTION_ERRORS=$(grep "$DATE_FILTER" "$MAIL_LOG" 2>/dev/null | grep -c "Connection refused\\|Connection timed out\\|Network is unreachable" || echo "0")
log_message "Connection errors: $CONNECTION_ERRORS"

# Authentication failures
AUTH_FAILURES=$(grep "$DATE_FILTER" "$MAIL_LOG" 2>/dev/null | grep -c "authentication failed" || echo "0")
log_message "Authentication failures: $AUTH_FAILURES"

# TLS connections
TLS_COUNT=$(grep "$DATE_FILTER" "$MAIL_LOG" 2>/dev/null | grep -c "TLS connection" || echo "0")
log_message "TLS connections: $TLS_COUNT"

# Generate HTML Report
HTML_REPORT="$REPORT_DIR/mail-analysis-${REPORT_DATE}.html"
log_message "Generating HTML report..."

cat > "$HTML_REPORT" << 'HTMLEOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Mail Log Analysis - ${REPORT_DATE}</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h1 { color: #333; border-bottom: 3px solid #2196F3; padding-bottom: 10px; }
        h2 { color: #555; margin-top: 30px; }
        .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 15px; margin: 20px 0; }
        .stat-card { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 20px; border-radius: 8px; color: white; }
        .stat-value { font-size: 2em; font-weight: bold; }
        .stat-label { margin-top: 5px; opacity: 0.9; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #2196F3; color: white; }
        tr:hover { background-color: #f5f5f5; }
        .metric-good { color: #4CAF50; font-weight: bold; }
        .metric-warning { color: #FF9800; font-weight: bold; }
        .metric-bad { color: #F44336; font-weight: bold; }
        .footer { margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd; color: #777; text-align: center; }
    </style>
</head>
<body>
    <div class="container">
        <h1>📧 Mail Log Analysis Report</h1>
        <p><strong>Date:</strong> ${REPORT_DATE}</p>
        <p><strong>Period:</strong> ${ANALYSIS_PERIOD}</p>
        <p><strong>Generated:</strong> ${TIMESTAMP}</p>
        
        <h2>📊 Overview Statistics</h2>
        <div class="stats">
            <div class="stat-card">
                <div class="stat-value">${SENT_COUNT}</div>
                <div class="stat-label">Emails Sent</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">${RECEIVED_COUNT}</div>
                <div class="stat-label">Emails Received</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">${BOUNCED_COUNT}</div>
                <div class="stat-label">Bounced</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">${REJECTED_COUNT}</div>
                <div class="stat-label">Rejected</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">${SPAM_BLOCKED}</div>
                <div class="stat-label">Spam Blocked</div>
            </div>
        </div>
        
        <h2>📈 Performance Metrics</h2>
        <table>
            <tr>
                <th>Metric</th>
                <th>Value</th>
                <th>Status</th>
            </tr>
            <tr>
                <td>Bounce Rate</td>
                <td>${BOUNCE_RATE}%</td>
                <td class="$([ ${BOUNCE_RATE%.*} -lt 5 ] && echo 'metric-good' || echo 'metric-warning')">$([ ${BOUNCE_RATE%.*} -lt 5 ] && echo 'Good' || echo 'High')</td>
            </tr>
            <tr>
                <td>Average Delivery Time</td>
                <td>${AVG_DELAY}s</td>
                <td class="metric-good">Normal</td>
            </tr>
            <tr>
                <td>Connection Errors</td>
                <td>${CONNECTION_ERRORS}</td>
                <td class="$([ $CONNECTION_ERRORS -lt 10 ] && echo 'metric-good' || echo 'metric-warning')">$([ $CONNECTION_ERRORS -lt 10 ] && echo 'Low' || echo 'High')</td>
            </tr>
            <tr>
                <td>Auth Failures</td>
                <td>${AUTH_FAILURES}</td>
                <td class="$([ $AUTH_FAILURES -lt 5 ] && echo 'metric-good' || echo 'metric-warning')">$([ $AUTH_FAILURES -lt 5 ] && echo 'Normal' || echo 'High')</td>
            </tr>
            <tr>
                <td>TLS Connections</td>
                <td>${TLS_COUNT}</td>
                <td class="metric-good">Active</td>
            </tr>
        </table>
        
        <h2>👤 Top 10 Senders</h2>
        <table>
            <tr>
                <th>Count</th>
                <th>Sender</th>
            </tr>
HTMLEOF

echo "$TOP_SENDERS" | while read count sender; do
    echo "            <tr><td>$count</td><td>$sender</td></tr>" >> "$HTML_REPORT"
done

cat >> "$HTML_REPORT" << 'HTMLEOF'
        </table>
        
        <h2>📨 Top 10 Recipients</h2>
        <table>
            <tr>
                <th>Count</th>
                <th>Recipient</th>
            </tr>
HTMLEOF

echo "$TOP_RECIPIENTS" | while read count recipient; do
    echo "            <tr><td>$count</td><td>$recipient</td></tr>" >> "$HTML_REPORT"
done

cat >> "$HTML_REPORT" << 'HTMLEOF'
        </table>
        
        <h2>🌐 Top 10 External Domains</h2>
        <table>
            <tr>
                <th>Count</th>
                <th>Domain</th>
            </tr>
HTMLEOF

echo "$TOP_DOMAINS" | while read count domain; do
    echo "            <tr><td>$count</td><td>$domain</td></tr>" >> "$HTML_REPORT"
done

cat >> "$HTML_REPORT" << HTMLEOF
        </table>
        
        <h2>❌ Top Rejection Reasons</h2>
        <table>
            <tr>
                <th>Count</th>
                <th>Reason</th>
            </tr>
$(echo "$REJECTION_REASONS" | while read count reason; do
    echo "            <tr><td>$count</td><td>$reason</td></tr>"
done)
        </table>
        
        <div class="footer">
            <p>Report generated automatically by analyze-mail-logs.sh</p>
            <p>Server: $(hostname)</p>
        </div>
    </div>
</body>
</html>
HTMLEOF

log_message "HTML report generated successfully"

# Generate JSON Report
JSON_REPORT="$REPORT_DIR/mail-analysis-${REPORT_DATE}.json"

cat > "$JSON_REPORT" << EOF
{
  "date": "$REPORT_DATE",
  "period": "$ANALYSIS_PERIOD",
  "timestamp": "$(date -Iseconds)",
  "statistics": {
    "sent": ${SENT_COUNT},
    "received": ${RECEIVED_COUNT},
    "bounced": ${BOUNCED_COUNT},
    "deferred": ${DEFERRED_COUNT},
    "rejected": ${REJECTED_COUNT},
    "spam_blocked": ${SPAM_BLOCKED},
    "bounce_rate": ${BOUNCE_RATE},
    "avg_delivery_time": "${AVG_DELAY}",
    "connection_errors": ${CONNECTION_ERRORS},
    "auth_failures": ${AUTH_FAILURES},
    "tls_connections": ${TLS_COUNT}
  },
  "top_senders": [
$(echo "$TOP_SENDERS" | awk '{print "    {\"count\": "$1", \"sender\": \""$2"\"}," }' | sed '$ s/,$//')
  ],
  "top_recipients": [
$(echo "$TOP_RECIPIENTS" | awk '{print "    {\"count\": "$1", \"recipient\": \""$2"\"}," }' | sed '$ s/,$//')
  ],
  "top_domains": [
$(echo "$TOP_DOMAINS" | awk '{print "    {\"count\": "$1", \"domain\": \""$2"\"}," }' | sed '$ s/,$//')
  ]
}
EOF

log_message "JSON report generated successfully"

# Generate text summary
SUMMARY_FILE="$REPORT_DIR/mail-analysis-${REPORT_DATE}.txt"
cat > "$SUMMARY_FILE" << EOF
===================================================
MAIL LOG ANALYSIS REPORT
===================================================
Date: $REPORT_DATE
Period: $ANALYSIS_PERIOD
Generated: $TIMESTAMP

STATISTICS
---------------------------------------------------
Sent:                  $SENT_COUNT
Received:              $RECEIVED_COUNT
Bounced:               $BOUNCED_COUNT
Deferred:              $DEFERRED_COUNT
Rejected:              $REJECTED_COUNT
Spam Blocked:          $SPAM_BLOCKED

PERFORMANCE METRICS
---------------------------------------------------
Bounce Rate:           ${BOUNCE_RATE}%
Avg Delivery Time:     ${AVG_DELAY}s
Connection Errors:     $CONNECTION_ERRORS
Auth Failures:         $AUTH_FAILURES
TLS Connections:       $TLS_COUNT

TOP 10 SENDERS
---------------------------------------------------
$TOP_SENDERS

TOP 10 RECIPIENTS
---------------------------------------------------
$TOP_RECIPIENTS

TOP 10 EXTERNAL DOMAINS
---------------------------------------------------
$TOP_DOMAINS

TOP REJECTION REASONS
---------------------------------------------------
$REJECTION_REASONS

===================================================
Report generated by analyze-mail-logs.sh
===================================================
EOF

log_message "Text report generated successfully"

# Keep only last 30 days of reports
find "$REPORT_DIR" -name "mail-analysis-*.html" -mtime +30 -delete 2>/dev/null
find "$REPORT_DIR" -name "mail-analysis-*.json" -mtime +30 -delete 2>/dev/null
find "$REPORT_DIR" -name "mail-analysis-*.txt" -mtime +30 -delete 2>/dev/null

log_message "=== MAIL LOG ANALYSIS COMPLETE ==="
log_message "Reports saved to: $REPORT_DIR"

exit 0
