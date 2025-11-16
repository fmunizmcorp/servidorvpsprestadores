#!/bin/bash

#############################################################################
# MONITOR.SH - System Monitoring Script
# Monitora CPU, RAM, Disco, Serviços
# Alerta se recursos > 80%
#############################################################################

# Configuration
ALERT_THRESHOLD=80
LOG_FILE="/var/log/webserver/monitor.log"
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

log_message "=== STARTING SYSTEM MONITOR ==="

# Check CPU
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 | cut -d'.' -f1)
log_message "CPU Usage: ${CPU_USAGE}%"

if [ "$CPU_USAGE" -gt "$ALERT_THRESHOLD" ]; then
    log_message "ALERT: CPU usage is above threshold!"
    send_alert "ALERT: High CPU Usage" "CPU usage is at ${CPU_USAGE}%"
fi

# Check Memory
MEMORY_USAGE=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100}')
log_message "Memory Usage: ${MEMORY_USAGE}%"

if [ "$MEMORY_USAGE" -gt "$ALERT_THRESHOLD" ]; then
    log_message "ALERT: Memory usage is above threshold!"
    send_alert "ALERT: High Memory Usage" "Memory usage is at ${MEMORY_USAGE}%"
fi

# Check Disk
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
log_message "Disk Usage: ${DISK_USAGE}%"

if [ "$DISK_USAGE" -gt "$ALERT_THRESHOLD" ]; then
    log_message "ALERT: Disk usage is above threshold!"
    send_alert "ALERT: High Disk Usage" "Disk usage is at ${DISK_USAGE}%"
fi

# Check Services
SERVICES=("nginx" "php8.3-fpm" "mariadb" "redis-server" "postfix" "dovecot" "fail2ban")

log_message "=== CHECKING SERVICES ==="

for service in "${SERVICES[@]}"; do
    if systemctl is-active --quiet "$service"; then
        log_message "$service: RUNNING"
    else
        log_message "ALERT: $service is NOT RUNNING!"
        send_alert "ALERT: Service Down" "$service is not running!"
        
        # Try to restart
        log_message "Attempting to restart $service..."
        systemctl restart "$service"
        sleep 2
        
        if systemctl is-active --quiet "$service"; then
            log_message "$service restarted successfully"
            send_alert "INFO: Service Restarted" "$service was restarted successfully"
        else
            log_message "CRITICAL: Failed to restart $service"
            send_alert "CRITICAL: Service Restart Failed" "Failed to restart $service"
        fi
    fi
done

# Check Load Average
LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
log_message "Load Average (1min): $LOAD_AVG"

# Get number of CPUs
CPU_COUNT=$(nproc)
LOAD_THRESHOLD=$((CPU_COUNT * 2))

# Compare load (basic check)
if [ "$(echo "$LOAD_AVG > $LOAD_THRESHOLD" | bc 2>/dev/null)" = "1" ]; then
    log_message "ALERT: Load average is high!"
    send_alert "ALERT: High Load Average" "Load average is $LOAD_AVG (threshold: $LOAD_THRESHOLD)"
fi

# Check for zombie processes
ZOMBIE_COUNT=$(ps aux | awk '$8 ~ /Z/ {count++} END {print count+0}')
log_message "Zombie Processes: $ZOMBIE_COUNT"

if [ "$ZOMBIE_COUNT" -gt 0 ]; then
    log_message "WARNING: Found $ZOMBIE_COUNT zombie processes"
    ps aux | awk '$8 ~ /Z/' | tee -a "$LOG_FILE"
fi

# Check network connectivity
if ping -c 1 8.8.8.8 &>/dev/null; then
    log_message "Network: OK"
else
    log_message "ALERT: Network connectivity issues!"
    send_alert "ALERT: Network Down" "Cannot reach external network"
fi

# Summary
log_message "=== MONITOR SUMMARY ==="
log_message "CPU: ${CPU_USAGE}% | Memory: ${MEMORY_USAGE}% | Disk: ${DISK_USAGE}%"
log_message "Services OK: All checked"
log_message "=== MONITOR COMPLETE ==="

# Generate JSON output for API
JSON_OUTPUT="/var/log/webserver/monitor-latest.json"
cat > "$JSON_OUTPUT" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "cpu_usage": ${CPU_USAGE},
  "memory_usage": ${MEMORY_USAGE},
  "disk_usage": ${DISK_USAGE},
  "load_average": ${LOAD_AVG},
  "zombie_processes": ${ZOMBIE_COUNT},
  "services": {
$(for service in "${SERVICES[@]}"; do
    if systemctl is-active --quiet "$service"; then
        echo "    \"$service\": \"running\","
    else
        echo "    \"$service\": \"stopped\","
    fi
done | sed '$ s/,$//')
  },
  "alerts": []
}
EOF

exit 0
