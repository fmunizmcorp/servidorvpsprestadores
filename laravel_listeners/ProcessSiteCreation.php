<?php

namespace App\Listeners;

use App\Events\SiteCreated;
use Illuminate\Support\Facades\Log;

class ProcessSiteCreation
{
    /**
     * Handle the event.
     */
    public function handle(SiteCreated $event): void
    {
        $site = $event->site;
        $options = $event->options;

        Log::info("SPRINT 36 EVENT: Processing site creation in background", [
            'site_id' => $site->id,
            'site_name' => $site->site_name,
            'listener' => 'ProcessSiteCreation'
        ]);

        try {
            // Copy scripts to /tmp
            $wrapperSource = storage_path('app/create-site-wrapper.sh');
            $postScriptSource = storage_path('app/post_site_creation.sh');
            $wrapperDest = "/tmp/create-site-wrapper.sh";
            $postScriptDest = "/tmp/post_site_creation.sh";

            if (file_exists($wrapperSource)) {
                copy($wrapperSource, $wrapperDest);
                chmod($wrapperDest, 0755);
                Log::info("SPRINT 36: Copied wrapper script", ['dest' => $wrapperDest]);
            } else {
                Log::error("SPRINT 36: Wrapper script not found", ['path' => $wrapperSource]);
                return;
            }

            if (file_exists($postScriptSource)) {
                copy($postScriptSource, $postScriptDest);
                chmod($postScriptDest, 0755);
                Log::info("SPRINT 36: Copied post-script", ['dest' => $postScriptDest]);
            } else {
                Log::error("SPRINT 36: Post-script not found", ['path' => $postScriptSource]);
                return;
            }

            // Build wrapper command arguments
            $args = [
                escapeshellarg($site->site_name),
                escapeshellarg($site->domain),
                escapeshellarg($site->php_version),
            ];

            if ($site->has_database) {
                // Database is enabled (no --no-db flag)
            } else {
                $args[] = '--no-db';
            }

            $args[] = "--template=" . escapeshellarg($site->template ?? 'php');

            // Execute wrapper script with sudo
            $wrapperCommand = "nohup /usr/bin/sudo -n " . $wrapperDest . " " . implode(" ", $args) . 
                            " > /tmp/site-creation-{$site->site_name}.log 2>&1 & echo $!";

            Log::info("SPRINT 36: Executing wrapper script via Event", [
                'command' => $wrapperCommand,
                'site_name' => $site->site_name
            ]);

            $wrapperPid = trim(shell_exec($wrapperCommand));

            Log::info("SPRINT 36: Wrapper script started", [
                'pid' => $wrapperPid,
                'site_name' => $site->site_name
            ]);

            // Execute post-creation script with delay
            $postCommand = "(sleep 10 && /usr/bin/sudo -n " . $postScriptDest . " " . 
                          escapeshellarg($site->site_name) . 
                          ") > /tmp/post-site-{$site->site_name}.log 2>&1 &";

            Log::info("SPRINT 36: Executing post-creation script via Event", [
                'command' => $postCommand,
                'site_name' => $site->site_name
            ]);

            shell_exec($postCommand);

            Log::info("SPRINT 36: Post-creation script started", [
                'site_name' => $site->site_name,
                'expected_completion' => '~25 seconds'
            ]);

        } catch (\Exception $e) {
            Log::error("SPRINT 36: Error in ProcessSiteCreation listener", [
                'site_name' => $site->site_name,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
        }
    }
}
