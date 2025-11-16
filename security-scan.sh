#!/bin/bash

#############################################################################
# SECURITY-SCAN.SH - Security Scanner
# ClamAV scan em /opt/webserver/sites/
# Quarentena automática de malware
#############################################################################

# Configuration
SCAN_PATH="/opt/webserver/sites"
QUARANTINE_PATH="/opt/webserver/quarantine"
LOG_FILE="/var/log/webserver/security-scan.log"
EMAIL_ALERT="admin@localhost"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Create directories
mkdir -p "$QUARANTINE_PATH"
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

log_message "=== STARTING SECURITY SCAN ==="

# Update ClamAV signatures
log_message "Updating ClamAV signatures..."
freshclam --quiet 2>&1 | tee -a "$LOG_FILE"

if [ $? -eq 0 ]; then
    log_message "ClamAV signatures updated successfully"
else
    log_message "WARNING: Failed to update ClamAV signatures"
fi

# Run ClamAV scan
log_message "Scanning: $SCAN_PATH"
SCAN_REPORT="/tmp/clamav-scan-$(date +%Y%m%d_%H%M%S).txt"

clamscan -r -i --log="$SCAN_REPORT" "$SCAN_PATH"
SCAN_EXIT_CODE=$?

# Parse results
INFECTED_COUNT=$(grep -c "FOUND" "$SCAN_REPORT" 2>/dev/null || echo "0")
log_message "Scan complete. Infected files found: $INFECTED_COUNT"

if [ "$INFECTED_COUNT" -gt 0 ]; then
    log_message "ALERT: Malware detected!"
    
    # List infected files
    log_message "=== INFECTED FILES ==="
    grep "FOUND" "$SCAN_REPORT" | tee -a "$LOG_FILE"
    
    # Move infected files to quarantine
    log_message "=== QUARANTINING INFECTED FILES ==="
    
    while read -r line; do
        if [[ $line =~ (.+):[[:space:]](.+)FOUND ]]; then
            infected_file="${BASH_REMATCH[1]}"
            
            if [ -f "$infected_file" ]; then
                # Create quarantine subdir with timestamp
                quarantine_subdir="$QUARANTINE_PATH/$(date +%Y%m%d_%H%M%S)"
                mkdir -p "$quarantine_subdir"
                
                # Move file
                filename=$(basename "$infected_file")
                mv "$infected_file" "$quarantine_subdir/$filename"
                
                if [ $? -eq 0 ]; then
                    log_message "Quarantined: $infected_file -> $quarantine_subdir/$filename"
                else
                    log_message "ERROR: Failed to quarantine $infected_file"
                fi
                
                # Create placeholder
                echo "This file was quarantined due to malware detection on $TIMESTAMP" > "$infected_file.QUARANTINED"
            fi
        fi
    done < <(grep "FOUND" "$SCAN_REPORT")
    
    # Send alert email
    ALERT_MESSAGE="Security scan found $INFECTED_COUNT infected files.\n\n"
    ALERT_MESSAGE+="Files have been quarantined to: $QUARANTINE_PATH\n\n"
    ALERT_MESSAGE+="Details:\n"
    ALERT_MESSAGE+="$(grep 'FOUND' $SCAN_REPORT)"
    
    send_alert "ALERT: Malware Detected" "$ALERT_MESSAGE"
    log_message "Alert email sent"
else
    log_message "No malware detected - system clean"
fi

# Generate scan summary
log_message "=== SCAN SUMMARY ==="
log_message "Scan path: $SCAN_PATH"
log_message "Infected files: $INFECTED_COUNT"
log_message "Quarantined: $INFECTED_COUNT"
log_message "Report: $SCAN_REPORT"

# Keep last 10 scan reports
cd /tmp && ls -t clamav-scan-*.txt 2>/dev/null | tail -n +11 | xargs rm -f 2>/dev/null

# Generate JSON report
JSON_REPORT="/var/log/webserver/security-scan-latest.json"
cat > "$JSON_REPORT" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "scan_path": "$SCAN_PATH",
  "infected_count": ${INFECTED_COUNT},
  "quarantined_count": ${INFECTED_COUNT},
  "scan_report": "$SCAN_REPORT",
  "status": "$([ $INFECTED_COUNT -eq 0 ] && echo 'clean' || echo 'infected')"
}
EOF

log_message "=== SECURITY SCAN COMPLETE ==="

# Exit with appropriate code
if [ "$INFECTED_COUNT" -gt 0 ]; then
    exit 1
else
    exit 0
fi
