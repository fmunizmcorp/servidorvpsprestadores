#!/usr/bin/env php
<?php

// Test Dashboard Controller Directly
// This will test if the dashboard controller works without HTTP

require __DIR__ . '/../../opt/webserver/admin-panel/vendor/autoload.php';

$app = require_once __DIR__ . '/../../opt/webserver/admin-panel/bootstrap/app.php';

$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

// Test DashboardController methods
$controller = new \App\Http\Controllers\DashboardController();

echo "===================================\n";
echo "Testing DashboardController Methods\n";
echo "===================================\n\n";

try {
    echo "1. Testing getMetrics()...\n";
    $metrics = $controller->getMetrics();
    echo "✅ getMetrics() success\n";
    echo "   CPU Usage: " . $metrics['cpu']['usage'] . "%\n";
    echo "   Memory Usage: " . $metrics['memory']['usage'] . "%\n";
    echo "   Disk Usage: " . $metrics['disk']['usage'] . "%\n\n";
} catch (\Exception $e) {
    echo "❌ getMetrics() failed: " . $e->getMessage() . "\n\n";
}

try {
    echo "2. Testing getServicesStatus()...\n";
    $services = $controller->getServicesStatus();
    echo "✅ getServicesStatus() success\n";
    foreach ($services as $name => $service) {
        echo "   " . $service['name'] . ": " . $service['status'] . "\n";
    }
    echo "\n";
} catch (\Exception $e) {
    echo "❌ getServicesStatus() failed: " . $e->getMessage() . "\n\n";
}

try {
    echo "3. Testing getSummary()...\n";
    $summary = $controller->getSummary();
    echo "✅ getSummary() success\n";
    echo "   Sites: " . $summary['sites'] . "\n";
    echo "   Email Domains: " . $summary['email_domains'] . "\n";
    echo "   Email Accounts: " . $summary['email_accounts'] . "\n";
    echo "   Uptime: " . $summary['uptime'] . "\n\n";
} catch (\Exception $e) {
    echo "❌ getSummary() failed: " . $e->getMessage() . "\n\n";
}

echo "===================================\n";
echo "All tests completed!\n";
echo "===================================\n";
