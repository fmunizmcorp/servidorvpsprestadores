<?php
// Test if Site creation via Controller saves to database

require '/opt/webserver/admin-panel/vendor/autoload.php';

$app = require_once '/opt/webserver/admin-panel/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\Site;

echo "Testing Site model...\n";
echo "Sites in database: " . Site::count() . "\n";

// Test creating a site record directly
$testSite = Site::create([
    'site_name' => 'controllertest' . time(),
    'domain' => 'controllertest.local',
    'php_version' => '8.3',
    'has_database' => true,
    'database_name' => 'db_controllertest',
    'database_user' => 'controllertest',
    'template' => 'php',
    'status' => 'active',
    'ssl_enabled' => true,
]);

echo "Site created successfully!\n";
echo "Site ID: " . $testSite->id . "\n";
echo "Site Name: " . $testSite->site_name . "\n";
echo "Total sites now: " . Site::count() . "\n";
