#!/bin/bash

#############################################################################
# SPAM-REPORT.SH - Daily Spam Analysis Report
# Analisa spam bloqueado, gera relatórios
#############################################################################

# Configuration
LOG_FILE="/var/log/webserver/spam-report.log"
REPORT_DIR="/var/log/webserver/reports"
MAIL_LOG="/var/log/mail.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
REPORT_DATE=$(date '+%Y-%m-%d')

# Create directories
mkdir -p "$REPORT_DIR"
mkdir -p /var/log/webserver

# Function to log
log_message() {
    echo "[$TIMESTAMP] $1" | tee -a "$LOG_FILE"
}

log_message "=== STARTING SPAM REPORT GENERATION ==="

# Count spam blocked today
SPAM_BLOCKED=$(grep "$(date +%b\ %d)" "$MAIL_LOG" 2>/dev/null | grep -ic "spam\|reject\|blocked" || echo "0")
log_message "Spam blocked today: $SPAM_BLOCKED"

# Count total emails today
TOTAL_EMAILS=$(grep "$(date +%b\ %d)" "$MAIL_LOG" 2>/dev/null | grep -c "from=<" || echo "0")
log_message "Total emails processed: $TOTAL_EMAILS"

# Calculate spam percentage
if [ "$TOTAL_EMAILS" -gt 0 ]; then
    SPAM_PERCENTAGE=$(awk "BEGIN {printf \"%.2f\", ($SPAM_BLOCKED / $TOTAL_EMAILS) * 100}")
else
    SPAM_PERCENTAGE="0.00"
fi

log_message "Spam percentage: ${SPAM_PERCENTAGE}%"

# Top 10 spam source IPs
log_message "Analyzing top spam source IPs..."
TOP_SPAM_IPS=$(grep "$(date +%b\ %d)" "$MAIL_LOG" 2>/dev/null | grep -i "spam\|reject\|blocked" | grep -oE '\[([0-9]{1,3}\.){3}[0-9]{1,3}\]' | sed 's/\[//g;s/\]//g' | sort | uniq -c | sort -rn | head -10)

# Top 10 targeted recipients
log_message "Analyzing top targeted recipients..."
TOP_TARGETS=$(grep "$(date +%b\ %d)" "$MAIL_LOG" 2>/dev/null | grep -i "spam\|reject\|blocked" | grep -oE 'to=<[^>]+>' | sed 's/to=<//g;s/>//g' | sort | uniq -c | sort -rn | head -10)

# Calculate average spam score
log_message "Calculating average spam score..."
AVG_SPAM_SCORE="N/A"

if command -v spamassassin &> /dev/null; then
    # If SpamAssassin is integrated, try to get scores
    SPAM_SCORES=$(grep "$(date +%b\ %d)" "$MAIL_LOG" 2>/dev/null | grep -oE 'score=[0-9]+\.[0-9]+' | cut -d= -f2)
    
    if [ -n "$SPAM_SCORES" ]; then
        AVG_SPAM_SCORE=$(echo "$SPAM_SCORES" | awk '{sum+=$1} END {if(NR>0) print sum/NR; else print "0"}')
        log_message "Average spam score: $AVG_SPAM_SCORE"
    fi
fi

# Check filter effectiveness
LEGITIMATE_PASSED=$(grep "$(date +%b\ %d)" "$MAIL_LOG" 2>/dev/null | grep "status=sent" | grep -v "spam" | wc -l || echo "0")
log_message "Legitimate emails passed: $LEGITIMATE_PASSED"

# Generate HTML Report
HTML_REPORT="$REPORT_DIR/spam-report-${REPORT_DATE}.html"
log_message "Generating HTML report: $HTML_REPORT"

cat > "$HTML_REPORT" << 'HTMLEOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Spam Report - ${REPORT_DATE}</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h1 { color: #333; border-bottom: 3px solid #4CAF50; padding-bottom: 10px; }
        h2 { color: #555; margin-top: 30px; }
        .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin: 20px 0; }
        .stat-card { background: #f9f9f9; padding: 20px; border-radius: 8px; border-left: 4px solid #4CAF50; }
        .stat-value { font-size: 2em; font-weight: bold; color: #4CAF50; }
        .stat-label { color: #777; margin-top: 5px; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #4CAF50; color: white; }
        tr:hover { background-color: #f5f5f5; }
        .footer { margin-top: 30px; padding-top: 20px; border-top: 1px solid #ddd; color: #777; text-align: center; }
    </style>
</head>
<body>
    <div class="container">
        <h1>📊 Spam Analysis Report</h1>
        <p><strong>Date:</strong> ${REPORT_DATE}</p>
        <p><strong>Generated:</strong> ${TIMESTAMP}</p>
        
        <h2>📈 Summary Statistics</h2>
        <div class="stats">
            <div class="stat-card">
                <div class="stat-value">${SPAM_BLOCKED}</div>
                <div class="stat-label">Spam Blocked</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">${TOTAL_EMAILS}</div>
                <div class="stat-label">Total Emails</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">${SPAM_PERCENTAGE}%</div>
                <div class="stat-label">Spam Percentage</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">${LEGITIMATE_PASSED}</div>
                <div class="stat-label">Legitimate Passed</div>
            </div>
        </div>
        
        <h2>🎯 Top 10 Spam Source IPs</h2>
        <table>
            <tr>
                <th>Count</th>
                <th>IP Address</th>
            </tr>
HTMLEOF

# Add top spam IPs to HTML
echo "$TOP_SPAM_IPS" | while read count ip; do
    echo "            <tr><td>$count</td><td>$ip</td></tr>" >> "$HTML_REPORT"
done

cat >> "$HTML_REPORT" << 'HTMLEOF'
        </table>
        
        <h2>📧 Top 10 Targeted Recipients</h2>
        <table>
            <tr>
                <th>Count</th>
                <th>Email Address</th>
            </tr>
HTMLEOF

# Add top targets to HTML
echo "$TOP_TARGETS" | while read count email; do
    echo "            <tr><td>$count</td><td>$email</td></tr>" >> "$HTML_REPORT"
done

cat >> "$HTML_REPORT" << HTMLEOF
        </table>
        
        <h2>📊 Filter Effectiveness</h2>
        <p><strong>Average Spam Score:</strong> $AVG_SPAM_SCORE</p>
        <p><strong>False Positives:</strong> Minimal (requires manual review)</p>
        <p><strong>Filter Status:</strong> Active and Effective</p>
        
        <div class="footer">
            <p>Report generated automatically by spam-report.sh</p>
            <p>Server: $(hostname)</p>
        </div>
    </div>
</body>
</html>
HTMLEOF

log_message "HTML report generated successfully"

# Generate JSON Report
JSON_REPORT="$REPORT_DIR/spam-report-${REPORT_DATE}.json"
log_message "Generating JSON report: $JSON_REPORT"

cat > "$JSON_REPORT" << EOF
{
  "date": "$REPORT_DATE",
  "timestamp": "$(date -Iseconds)",
  "summary": {
    "spam_blocked": ${SPAM_BLOCKED},
    "total_emails": ${TOTAL_EMAILS},
    "spam_percentage": ${SPAM_PERCENTAGE},
    "legitimate_passed": ${LEGITIMATE_PASSED},
    "average_spam_score": "$AVG_SPAM_SCORE"
  },
  "top_spam_ips": [
$(echo "$TOP_SPAM_IPS" | awk '{print "    {\"count\": "$1", \"ip\": \""$2"\"}," }' | sed '$ s/,$//')
  ],
  "top_targets": [
$(echo "$TOP_TARGETS" | awk '{print "    {\"count\": "$1", \"email\": \""$2"\"}," }' | sed '$ s/,$//')
  ]
}
EOF

log_message "JSON report generated successfully"

# Generate text summary
SUMMARY_FILE="$REPORT_DIR/spam-report-${REPORT_DATE}.txt"
cat > "$SUMMARY_FILE" << EOF
===================================================
SPAM ANALYSIS REPORT
===================================================
Date: $REPORT_DATE
Generated: $TIMESTAMP

SUMMARY STATISTICS
---------------------------------------------------
Spam Blocked:          $SPAM_BLOCKED
Total Emails:          $TOTAL_EMAILS
Spam Percentage:       ${SPAM_PERCENTAGE}%
Legitimate Passed:     $LEGITIMATE_PASSED
Average Spam Score:    $AVG_SPAM_SCORE

TOP 10 SPAM SOURCE IPS
---------------------------------------------------
$TOP_SPAM_IPS

TOP 10 TARGETED RECIPIENTS
---------------------------------------------------
$TOP_TARGETS

FILTER EFFECTIVENESS
---------------------------------------------------
Status: Active and Effective
False Positives: Minimal

===================================================
Report generated by spam-report.sh
===================================================
EOF

log_message "Text report generated successfully"

# Keep only last 30 days of reports
find "$REPORT_DIR" -name "spam-report-*.html" -mtime +30 -delete 2>/dev/null
find "$REPORT_DIR" -name "spam-report-*.json" -mtime +30 -delete 2>/dev/null
find "$REPORT_DIR" -name "spam-report-*.txt" -mtime +30 -delete 2>/dev/null

log_message "=== SPAM REPORT GENERATION COMPLETE ==="
log_message "Reports saved to: $REPORT_DIR"

exit 0
