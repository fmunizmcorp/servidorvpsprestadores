<?php

// ========================================
// SPRINT 8 IMPLEMENTATION
// Dashboard Historical Graphs + Email Alerts
// ========================================

// ========================================
// FILE 1: Migration - create_metrics_history_table.php
// ========================================
/*
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('metrics_history', function (Blueprint $table) {
            $table->id();
            $table->decimal('cpu_usage', 5, 2);
            $table->decimal('memory_usage', 5, 2);
            $table->decimal('disk_usage', 5, 2);
            $table->string('cpu_load_1min')->nullable();
            $table->string('cpu_load_5min')->nullable();
            $table->string('cpu_load_15min')->nullable();
            $table->timestamps();
            
            // Index for faster queries
            $table->index('created_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('metrics_history');
    }
};
*/

// ========================================
// FILE 2: Model - MetricsHistory.php
// ========================================
/*
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class MetricsHistory extends Model
{
    use HasFactory;

    protected $table = 'metrics_history';
    
    protected $fillable = [
        'cpu_usage',
        'memory_usage',
        'disk_usage',
        'cpu_load_1min',
        'cpu_load_5min',
        'cpu_load_15min'
    ];
    
    protected $casts = [
        'cpu_usage' => 'float',
        'memory_usage' => 'float',
        'disk_usage' => 'float',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];
}
*/

// ========================================
// FILE 3: Console Command - CollectMetrics.php
// ========================================
/*
<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\MetricsHistory;
use Illuminate\Support\Facades\Mail;
use App\Mail\HighUsageAlert;

class CollectMetrics extends Command
{
    protected $signature = 'metrics:collect';
    protected $description = 'Collect system metrics and store in database';

    public function handle()
    {
        // Collect CPU metrics
        $cpuLoad = sys_getloadavg();
        $cpuUsage = round($cpuLoad[0] * 100 / 2, 2);
        
        // Collect memory metrics
        $memInfo = shell_exec("free | grep Mem | awk '{print $3/$2 * 100.0}'");
        $memUsage = round(floatval($memInfo), 2);
        
        // Collect disk metrics
        $diskTotal = disk_total_space("/opt/webserver");
        $diskFree = disk_free_space("/opt/webserver");
        $diskUsage = round(($diskTotal - $diskFree) / $diskTotal * 100, 2);
        
        // Store in database
        $metrics = MetricsHistory::create([
            'cpu_usage' => $cpuUsage,
            'memory_usage' => $memUsage,
            'disk_usage' => $diskUsage,
            'cpu_load_1min' => (string) $cpuLoad[0],
            'cpu_load_5min' => (string) $cpuLoad[1],
            'cpu_load_15min' => (string) $cpuLoad[2],
        ]);
        
        // Check for high usage and send alerts
        if ($cpuUsage >= 90 || $memUsage >= 90 || $diskUsage >= 90) {
            $this->sendHighUsageAlert($cpuUsage, $memUsage, $diskUsage);
        }
        
        // Clean old metrics (keep last 7 days)
        MetricsHistory::where('created_at', '<', now()->subDays(7))->delete();
        
        $this->info("Metrics collected successfully!");
        return 0;
    }
    
    private function sendHighUsageAlert($cpuUsage, $memUsage, $diskUsage)
    {
        try {
            // Get admin email from config or use default
            $adminEmail = config('mail.admin_email', 'admin@72.61.53.222');
            
            $alertData = [
                'cpu' => $cpuUsage,
                'memory' => $memUsage,
                'disk' => $diskUsage,
                'server' => '72.61.53.222',
                'timestamp' => now()->format('Y-m-d H:i:s')
            ];
            
            Mail::to($adminEmail)->send(new HighUsageAlert($alertData));
            
            $this->warn("High usage alert sent to {$adminEmail}");
        } catch (\Exception $e) {
            $this->error("Failed to send alert email: " . $e->getMessage());
        }
    }
}
*/

// ========================================
// FILE 4: Mail - HighUsageAlert.php
// ========================================
/*
<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class HighUsageAlert extends Mailable
{
    use Queueable, SerializesModels;

    public $alertData;

    public function __construct($alertData)
    {
        $this->alertData = $alertData;
    }

    public function envelope(): Envelope
    {
        return new Envelope(
            subject: '🚨 High Resource Usage Alert - VPS 72.61.53.222',
        );
    }

    public function content(): Content
    {
        return new Content(
            view: 'emails.high-usage-alert',
        );
    }
}
*/

// ========================================
// FILE 5: DashboardController UPDATED
// ========================================
/*
Add these methods to DashboardController:

public function getHistoricalMetrics($hours = 24)
{
    $metrics = MetricsHistory::where('created_at', '>=', now()->subHours($hours))
        ->orderBy('created_at', 'asc')
        ->get();
    
    return [
        'labels' => $metrics->pluck('created_at')->map(fn($dt) => $dt->format('H:i')),
        'cpu' => $metrics->pluck('cpu_usage'),
        'memory' => $metrics->pluck('memory_usage'),
        'disk' => $metrics->pluck('disk_usage'),
    ];
}

public function apiHistoricalMetrics(Request $request)
{
    $hours = $request->get('hours', 24);
    return response()->json($this->getHistoricalMetrics($hours));
}
*/

// ========================================
// FILE 6: dashboard.blade.php - ADD CHARTS SECTION
// ========================================
/*
Add after the services section:

<!-- Historical Graphs -->
<div class="bg-white overflow-hidden shadow-sm sm:rounded-lg mb-6">
    <div class="p-6">
        <div class="flex items-center justify-between mb-4">
            <h3 class="text-lg font-semibold text-gray-900">Historical Metrics (Last 24 Hours)</h3>
            <select id="timeRange" class="border-gray-300 rounded-md shadow-sm focus:border-blue-300 focus:ring focus:ring-blue-200">
                <option value="24">Last 24 Hours</option>
                <option value="12">Last 12 Hours</option>
                <option value="6">Last 6 Hours</option>
                <option value="1">Last Hour</option>
            </select>
        </div>
        
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div>
                <h4 class="text-sm font-medium text-gray-700 mb-2">CPU Usage</h4>
                <canvas id="cpuChart" height="200"></canvas>
            </div>
            <div>
                <h4 class="text-sm font-medium text-gray-700 mb-2">Memory Usage</h4>
                <canvas id="memoryChart" height="200"></canvas>
            </div>
            <div>
                <h4 class="text-sm font-medium text-gray-700 mb-2">Disk Usage</h4>
                <canvas id="diskChart" height="200"></canvas>
            </div>
        </div>
    </div>
</div>

<!-- Chart.js Script -->
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
<script>
let cpuChart, memoryChart, diskChart;

function createCharts(data) {
    const chartOptions = (title, color) => ({
        type: 'line',
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: { display: false },
                title: { display: false }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    max: 100,
                    ticks: { callback: value => value + '%' }
                }
            }
        }
    });
    
    // CPU Chart
    const cpuCtx = document.getElementById('cpuChart').getContext('2d');
    if (cpuChart) cpuChart.destroy();
    cpuChart = new Chart(cpuCtx, {
        ...chartOptions('CPU Usage', 'rgb(59, 130, 246)'),
        data: {
            labels: data.labels,
            datasets: [{
                label: 'CPU %',
                data: data.cpu,
                borderColor: 'rgb(59, 130, 246)',
                backgroundColor: 'rgba(59, 130, 246, 0.1)',
                fill: true,
                tension: 0.4
            }]
        }
    });
    
    // Memory Chart
    const memCtx = document.getElementById('memoryChart').getContext('2d');
    if (memoryChart) memoryChart.destroy();
    memoryChart = new Chart(memCtx, {
        ...chartOptions('Memory Usage', 'rgb(34, 197, 94)'),
        data: {
            labels: data.labels,
            datasets: [{
                label: 'Memory %',
                data: data.memory,
                borderColor: 'rgb(34, 197, 94)',
                backgroundColor: 'rgba(34, 197, 94, 0.1)',
                fill: true,
                tension: 0.4
            }]
        }
    });
    
    // Disk Chart
    const diskCtx = document.getElementById('diskChart').getContext('2d');
    if (diskChart) diskChart.destroy();
    diskChart = new Chart(diskCtx, {
        ...chartOptions('Disk Usage', 'rgb(168, 85, 247)'),
        data: {
            labels: data.labels,
            datasets: [{
                label: 'Disk %',
                data: data.disk,
                borderColor: 'rgb(168, 85, 247)',
                backgroundColor: 'rgba(168, 85, 247, 0.1)',
                fill: true,
                tension: 0.4
            }]
        }
    });
}

function loadMetrics(hours = 24) {
    fetch(`/dashboard/api/historical-metrics?hours=${hours}`)
        .then(response => response.json())
        .then(data => createCharts(data))
        .catch(error => console.error('Error loading metrics:', error));
}

// Load on page load
document.addEventListener('DOMContentLoaded', () => {
    loadMetrics(24);
    
    // Update on time range change
    document.getElementById('timeRange').addEventListener('change', (e) => {
        loadMetrics(e.target.value);
    });
    
    // Auto-refresh every 5 minutes
    setInterval(() => {
        const hours = document.getElementById('timeRange').value;
        loadMetrics(hours);
    }, 300000);
});
</script>
*/

// ========================================
// FILE 7: Email View - high-usage-alert.blade.php
// ========================================
/*
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: #dc2626; color: white; padding: 20px; border-radius: 5px 5px 0 0; }
        .content { background: #f9fafb; padding: 20px; border: 1px solid #e5e7eb; }
        .metric { margin: 10px 0; padding: 10px; background: white; border-left: 4px solid #dc2626; }
        .footer { text-align: center; margin-top: 20px; font-size: 12px; color: #6b7280; }
        .high { color: #dc2626; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1 style="margin: 0;">🚨 High Resource Usage Alert</h1>
        </div>
        <div class="content">
            <p><strong>Server:</strong> {{ $alertData['server'] }}</p>
            <p><strong>Time:</strong> {{ $alertData['timestamp'] }}</p>
            <p>The following resource usage metrics have exceeded the 90% threshold:</p>
            
            @if($alertData['cpu'] >= 90)
            <div class="metric">
                <strong>CPU Usage:</strong> <span class="high">{{ $alertData['cpu'] }}%</span>
            </div>
            @endif
            
            @if($alertData['memory'] >= 90)
            <div class="metric">
                <strong>Memory Usage:</strong> <span class="high">{{ $alertData['memory'] }}%</span>
            </div>
            @endif
            
            @if($alertData['disk'] >= 90)
            <div class="metric">
                <strong>Disk Usage:</strong> <span class="high">{{ $alertData['disk'] }}%</span>
            </div>
            @endif
            
            <p style="margin-top: 20px;">
                Please log in to the admin panel to investigate and take necessary actions.
            </p>
            <p>
                <a href="https://72.61.53.222/admin" style="display: inline-block; padding: 10px 20px; background: #2563eb; color: white; text-decoration: none; border-radius: 5px;">
                    Access Admin Panel
                </a>
            </p>
        </div>
        <div class="footer">
            <p>This is an automated alert from VPS Admin Panel</p>
        </div>
    </div>
</body>
</html>
*/

// ========================================
// FILE 8: Route Addition to web.php
// ========================================
/*
Add to routes/web.php:

// Dashboard API for historical metrics
Route::get('/dashboard/api/historical-metrics', [DashboardController::class, 'apiHistoricalMetrics'])->name('dashboard.apiHistoricalMetrics');
*/

// ========================================
// FILE 9: Kernel.php - Schedule Metrics Collection
// ========================================
/*
Add to app/Console/Kernel.php in the schedule() method:

protected function schedule(Schedule $schedule): void
{
    // Collect metrics every 5 minutes
    $schedule->command('metrics:collect')->everyFiveMinutes();
}
*/
