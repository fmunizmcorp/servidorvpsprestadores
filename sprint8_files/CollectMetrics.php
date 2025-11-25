<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\MetricsHistory;
use Illuminate\Support\Facades\Mail;
use App\Mail\HighUsageAlert;

class CollectMetrics extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'metrics:collect';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Collect system metrics and store in database';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        try {
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
            
            $this->info("✅ Metrics collected: CPU={$cpuUsage}%, MEM={$memUsage}%, DISK={$diskUsage}%");
            
            // Check for high usage and send alerts
            if ($cpuUsage >= 90 || $memUsage >= 90 || $diskUsage >= 90) {
                $this->sendHighUsageAlert($cpuUsage, $memUsage, $diskUsage);
            }
            
            // Clean old metrics (keep last 7 days)
            $deleted = MetricsHistory::where('created_at', '<', now()->subDays(7))->delete();
            if ($deleted > 0) {
                $this->info("🗑️  Cleaned {$deleted} old metric records");
            }
            
            return 0;
            
        } catch (\Exception $e) {
            $this->error("❌ Failed to collect metrics: " . $e->getMessage());
            return 1;
        }
    }
    
    /**
     * Send high usage alert email
     */
    private function sendHighUsageAlert($cpuUsage, $memUsage, $diskUsage)
    {
        try {
            // Get admin email from config or use default
            $adminEmail = config('mail.admin_email', 'root@72.61.53.222');
            
            $alertData = [
                'cpu' => $cpuUsage,
                'memory' => $memUsage,
                'disk' => $diskUsage,
                'server' => '72.61.53.222',
                'timestamp' => now()->format('Y-m-d H:i:s')
            ];
            
            Mail::to($adminEmail)->send(new HighUsageAlert($alertData));
            
            $this->warn("🚨 High usage alert sent to {$adminEmail}");
            
        } catch (\Exception $e) {
            $this->error("❌ Failed to send alert email: " . $e->getMessage());
        }
    }
}
