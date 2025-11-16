#!/bin/bash

#############################################################################
# MINING-DETECT.SH - Cryptocurrency Mining Detection
# Detecta processos de mineração e high CPU suspicious
#############################################################################

# Configuration
CPU_THRESHOLD=80
LOG_FILE="/var/log/webserver/mining-detect.log"
EMAIL_ALERT="admin@localhost"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Known mining process names
MINING_PROCESSES=("xmrig" "minerd" "cpuminer" "ccminer" "ethminer" "phoenix" "claymore" "nanominer" "srbminer" "lolminer" "gminer" "t-rex" "nbminer")

# Known mining ports
MINING_PORTS=("3333" "4444" "5555" "14444" "45560" "45700" "9999")

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

log_message "=== STARTING MINING DETECTION ==="

# Track detected issues
DETECTED_COUNT=0

# Check for known mining processes
log_message "Checking for known mining processes..."

for process in "${MINING_PROCESSES[@]}"; do
    if pgrep -x "$process" > /dev/null; then
        PIDS=$(pgrep -x "$process" | tr '\n' ' ')
        log_message "ALERT: Mining process detected: $process (PIDs: $PIDS)"
        
        # Kill the process
        log_message "Killing mining process: $process"
        pkill -9 "$process"
        
        if [ $? -eq 0 ]; then
            log_message "Successfully killed: $process"
            send_alert "ALERT: Mining Process Killed" "Mining process $process was detected and terminated. PIDs: $PIDS"
        else
            log_message "ERROR: Failed to kill: $process"
        fi
        
        ((DETECTED_COUNT++))
    fi
done

# Check for suspicious high CPU processes
log_message "Checking for suspicious high CPU processes..."

HIGH_CPU_PROCESSES=$(ps aux --sort=-%cpu | head -n 11 | tail -n +2 | awk -v threshold="$CPU_THRESHOLD" '$3 > threshold {print $2":"$11":"$3}')

if [ -n "$HIGH_CPU_PROCESSES" ]; then
    log_message "High CPU processes detected:"
    
    while IFS=: read -r pid command cpu; do
        log_message "  PID: $pid | Command: $command | CPU: ${cpu}%"
        
        # Check if command looks suspicious
        if [[ "$command" =~ (curl|wget|bash|sh|python|perl) ]] && [ ! -f "$command" ]; then
            log_message "  SUSPICIOUS: Process using $command with high CPU"
            
            # Get more details
            CMDLINE=$(cat /proc/$pid/cmdline 2>/dev/null | tr '\0' ' ')
            log_message "  Full command: $CMDLINE"
            
            ((DETECTED_COUNT++))
        fi
    done <<< "$HIGH_CPU_PROCESSES"
fi

# Check for connections to mining pools
log_message "Checking for connections to mining pool ports..."

for port in "${MINING_PORTS[@]}"; do
    CONNECTIONS=$(netstat -tn 2>/dev/null | grep ":$port " | grep ESTABLISHED)
    
    if [ -n "$CONNECTIONS" ]; then
        log_message "ALERT: Connection to mining port detected: $port"
        log_message "$CONNECTIONS"
        
        # Extract remote IP
        REMOTE_IP=$(echo "$CONNECTIONS" | awk '{print $5}' | cut -d: -f1)
        log_message "Remote IP: $REMOTE_IP"
        
        # Find process using this connection
        PID=$(lsof -i :$port 2>/dev/null | grep ESTABLISHED | awk '{print $2}' | head -1)
        
        if [ -n "$PID" ]; then
            PROCESS_NAME=$(ps -p $PID -o comm= 2>/dev/null)
            log_message "Process: $PROCESS_NAME (PID: $PID)"
            
            # Kill suspicious process
            log_message "Killing suspicious process: $PID"
            kill -9 $PID 2>/dev/null
            
            send_alert "ALERT: Mining Connection Detected" "Connection to mining port $port detected from process $PROCESS_NAME (PID: $PID). Process terminated."
        fi
        
        ((DETECTED_COUNT++))
    fi
done

# Check for hidden processes (common mining technique)
log_message "Checking for hidden processes..."

HIDDEN_PROCS=$(ps aux | grep -E '\[.*\]' | grep -v '\[kworker' | grep -v '\[ksoftirqd' | grep -v grep)

if [ -n "$HIDDEN_PROCS" ]; then
    log_message "Potential hidden processes found:"
    echo "$HIDDEN_PROCS" | tee -a "$LOG_FILE"
fi

# Check cron jobs for suspicious entries
log_message "Checking cron jobs..."

for user in $(cut -f1 -d: /etc/passwd); do
    CRON_JOBS=$(crontab -u $user -l 2>/dev/null | grep -v '^#' | grep -v '^$')
    
    if [ -n "$CRON_JOBS" ]; then
        # Check for suspicious patterns in cron
        if echo "$CRON_JOBS" | grep -qE '(curl|wget|/tmp|/dev/shm)'; then
            log_message "ALERT: Suspicious cron job for user: $user"
            log_message "$CRON_JOBS"
            ((DETECTED_COUNT++))
        fi
    fi
done

# Check /tmp and /dev/shm for suspicious files
log_message "Checking temporary directories..."

SUSPICIOUS_FILES=$(find /tmp /dev/shm -type f -executable 2>/dev/null)

if [ -n "$SUSPICIOUS_FILES" ]; then
    log_message "Suspicious executable files in temp directories:"
    echo "$SUSPICIOUS_FILES" | tee -a "$LOG_FILE"
    
    # Optionally delete them
    # echo "$SUSPICIOUS_FILES" | xargs rm -f
fi

# Generate detection summary
log_message "=== DETECTION SUMMARY ==="
log_message "Detected issues: $DETECTED_COUNT"

if [ "$DETECTED_COUNT" -eq 0 ]; then
    log_message "No mining activity detected - system clean"
else
    log_message "ALERT: $DETECTED_COUNT potential mining activities detected!"
    send_alert "ALERT: Mining Activity Detected" "Mining detection found $DETECTED_COUNT suspicious activities. Check logs for details."
fi

# Generate JSON report
JSON_REPORT="/var/log/webserver/mining-detect-latest.json"
cat > "$JSON_REPORT" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "detected_count": ${DETECTED_COUNT},
  "status": "$([ $DETECTED_COUNT -eq 0 ] && echo 'clean' || echo 'detected')",
  "log_file": "$LOG_FILE"
}
EOF

log_message "=== MINING DETECTION COMPLETE ==="

# Exit with appropriate code
if [ "$DETECTED_COUNT" -gt 0 ]; then
    exit 1
else
    exit 0
fi
