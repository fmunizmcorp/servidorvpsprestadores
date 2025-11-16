#!/bin/bash

#############################################################################
# EMAIL-QUEUE-MONITOR.SH - Postfix Queue Monitoring
# Monitora fila de email, alerta problemas
#############################################################################

# Configuration
QUEUE_THRESHOLD=100
OLD_EMAIL_HOURS=24
LOG_FILE="/var/log/webserver/email-queue.log"
EMAIL_ALERT="admin@localhost"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Create log directory
mkdir -p /var/log/webserver

# Function to log
log_message() {
    echo "[$TIMESTAMP] $1" | tee -a "$LOG_FILE"
}

# Function to send alert
send_alert() {
    local subject="$1"
    local message="$2"
    echo "$message" | mail -s "$subject" "$EMAIL_ALERT" 2>/dev/null
}

log_message "=== STARTING EMAIL QUEUE MONITOR ==="

# Get queue size
QUEUE_SIZE=$(mailq | tail -1 | awk '{print $5}')

if [ -z "$QUEUE_SIZE" ] || [ "$QUEUE_SIZE" = "empty" ]; then
    QUEUE_SIZE=0
fi

log_message "Current queue size: $QUEUE_SIZE emails"

# Check if queue is above threshold
if [ "$QUEUE_SIZE" -gt "$QUEUE_THRESHOLD" ]; then
    log_message "ALERT: Queue size above threshold ($QUEUE_THRESHOLD)"
    send_alert "ALERT: Large Email Queue" "Email queue has $QUEUE_SIZE messages (threshold: $QUEUE_THRESHOLD)"
fi

# Get detailed queue info
if [ "$QUEUE_SIZE" -gt 0 ]; then
    log_message "=== QUEUE DETAILS ==="
    
    # Get queue summary
    QUEUE_SUMMARY=$(qshape active | head -10)
    log_message "Queue shape (active):"
    echo "$QUEUE_SUMMARY" | tee -a "$LOG_FILE"
    
    # Check for old emails in queue
    log_message "Checking for old emails (>$OLD_EMAIL_HOURS hours)..."
    
    OLD_EMAILS=$(find /var/spool/postfix/deferred -type f -mmin +$((OLD_EMAIL_HOURS * 60)) 2>/dev/null | wc -l)
    
    if [ "$OLD_EMAILS" -gt 0 ]; then
        log_message "ALERT: Found $OLD_EMAILS emails older than $OLD_EMAIL_HOURS hours"
        send_alert "ALERT: Old Emails in Queue" "$OLD_EMAILS emails have been in queue for more than $OLD_EMAIL_HOURS hours"
    fi
    
    # Get top senders
    log_message "Top senders in queue:"
    mailq | grep -oE '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' | sort | uniq -c | sort -rn | head -5 | tee -a "$LOG_FILE"
    
    # Get top recipients
    log_message "Top recipients in queue:"
    postqueue -p | grep -oE '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' | sort | uniq -c | sort -rn | head -5 | tee -a "$LOG_FILE"
    
    # Check for bounce messages
    BOUNCES=$(mailq | grep -c 'Mail Delivery Failed' || echo "0")
    log_message "Bounce messages: $BOUNCES"
    
    if [ "$BOUNCES" -gt 10 ]; then
        log_message "WARNING: High number of bounce messages"
    fi
fi

# Check Postfix status
POSTFIX_STATUS=$(systemctl is-active postfix)
log_message "Postfix status: $POSTFIX_STATUS"

if [ "$POSTFIX_STATUS" != "active" ]; then
    log_message "ALERT: Postfix is not running!"
    send_alert "CRITICAL: Postfix Down" "Postfix mail server is not running"
fi

# Check mail log for errors
ERROR_COUNT=$(tail -100 /var/log/mail.log 2>/dev/null | grep -c "error\|warning\|fatal" || echo "0")
log_message "Recent errors in mail.log: $ERROR_COUNT"

if [ "$ERROR_COUNT" -gt 20 ]; then
    log_message "WARNING: High number of errors in mail log"
    log_message "Last 10 errors:"
    tail -100 /var/log/mail.log | grep -i "error\|warning\|fatal" | tail -10 | tee -a "$LOG_FILE"
fi

# Calculate delivery rate
SENT_TODAY=$(grep "$(date +%b\ %d)" /var/log/mail.log 2>/dev/null | grep -c "status=sent" || echo "0")
FAILED_TODAY=$(grep "$(date +%b\ %d)" /var/log/mail.log 2>/dev/null | grep -c "status=bounced\|status=deferred" || echo "0")

TOTAL_TODAY=$((SENT_TODAY + FAILED_TODAY))
if [ "$TOTAL_TODAY" -gt 0 ]; then
    SUCCESS_RATE=$(awk "BEGIN {printf \"%.2f\", ($SENT_TODAY / $TOTAL_TODAY) * 100}")
else
    SUCCESS_RATE="0.00"
fi

log_message "=== DELIVERY STATS TODAY ==="
log_message "Sent: $SENT_TODAY"
log_message "Failed: $FAILED_TODAY"
log_message "Success rate: ${SUCCESS_RATE}%"

# Check disk space for mail spool
SPOOL_USAGE=$(df /var/spool/postfix | tail -1 | awk '{print $5}' | sed 's/%//')
log_message "Mail spool disk usage: ${SPOOL_USAGE}%"

if [ "$SPOOL_USAGE" -gt 80 ]; then
    log_message "ALERT: Mail spool disk usage high!"
    send_alert "ALERT: Mail Spool Disk Full" "Mail spool disk usage is at ${SPOOL_USAGE}%"
fi

# Generate summary
log_message "=== QUEUE SUMMARY ==="
log_message "Queue size: $QUEUE_SIZE"
log_message "Old emails: $OLD_EMAILS"
log_message "Bounces: $BOUNCES"
log_message "Success rate: ${SUCCESS_RATE}%"
log_message "Spool usage: ${SPOOL_USAGE}%"

# Generate JSON report
JSON_REPORT="/var/log/webserver/email-queue-latest.json"
cat > "$JSON_REPORT" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "queue_size": ${QUEUE_SIZE},
  "old_emails": ${OLD_EMAILS},
  "bounces": ${BOUNCES},
  "sent_today": ${SENT_TODAY},
  "failed_today": ${FAILED_TODAY},
  "success_rate": ${SUCCESS_RATE},
  "spool_usage": ${SPOOL_USAGE},
  "postfix_status": "$POSTFIX_STATUS",
  "status": "$([ $QUEUE_SIZE -lt $QUEUE_THRESHOLD ] && echo 'ok' || echo 'warning')"
}
EOF

log_message "=== EMAIL QUEUE MONITOR COMPLETE ==="

# Exit with appropriate code
if [ "$QUEUE_SIZE" -gt "$QUEUE_THRESHOLD" ] || [ "$POSTFIX_STATUS" != "active" ]; then
    exit 1
else
    exit 0
fi
