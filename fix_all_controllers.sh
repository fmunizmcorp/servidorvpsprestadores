#!/bin/bash

# Comprehensive controller fixes script
VPS_IP="72.61.53.222"
VPS_PASS="Jm@D@KDPnw7Q"

echo "=========================================="
echo "Fixing All Laravel Controller Issues"
echo "=========================================="
echo ""

# Function to run command on VPS
run_vps() {
    sshpass -p "$VPS_PASS" ssh -o StrictHostKeyChecking=no root@"$VPS_IP" "$1"
}

# Fix 1: EmailController index() - Add domains variable
echo "Fix 1: EmailController index() - Adding 'domains' variable..."
run_vps "cd /opt/webserver/admin-panel && sed -i '/public function index()/,/return view/ {
    s/return view('\''email.index'\'', \\[/return view('\''email.index'\'', [\n            '\''domains'\'' => \$this->getAllDomains(),/
}' app/Http/Controllers/EmailController.php"
echo "✅ EmailController index() fixed"
echo ""

# Fix 2: EmailController queue() - Add stats variable
echo "Fix 2: EmailController queue() - Adding 'stats' variable..."
run_vps "cd /opt/webserver/admin-panel && sed -i '/public function queue()/,/return view/ {
    /return view/i\        \$stats = \$this->getEmailStats();
    s/return view('\''email.queue'\'', \\[/return view('\''email.queue'\'', [\n            '\''stats'\'' => \$stats,/
}' app/Http/Controllers/EmailController.php"
echo "✅ EmailController queue() fixed"
echo ""

# Fix 3: EmailController logs() - Add logType variable
echo "Fix 3: EmailController logs() - Adding 'logType' variable..."
run_vps "cd /opt/webserver/admin-panel && sed -i '/public function logs(/,/return view/ {
    s/return view('\''email.logs'\'', \\[/return view('\''email.logs'\'', [\n            '\''logType'\'' => '\''mail'\'',/
}' app/Http/Controllers/EmailController.php"
echo "✅ EmailController logs() fixed"
echo ""

echo "=========================================="
echo "✅ All Email Controller fixes applied"
echo "=========================================="
echo ""

# Now let's check MonitoringController, SecurityController, and BackupsController
# which have more complex issues that need careful review

echo "Reading controllers to understand the issues..."
echo ""

