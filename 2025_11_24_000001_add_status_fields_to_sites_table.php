<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations - SPRINT57 v3.5
     * Add fields for background site creation tracking
     */
    public function up(): void
    {
        Schema::table('sites', function (Blueprint $table) {
            // Status field (if not exists)
            if (!Schema::hasColumn('sites', 'status')) {
                $table->string('status', 20)->default('active')->after('template');
            }
            
            // Creation tracking fields
            $table->integer('creation_pid')->nullable()->after('status')
                  ->comment('Process ID of background creation script');
            
            $table->string('creation_log', 255)->nullable()->after('creation_pid')
                  ->comment('Path to creation log file');
            
            $table->text('creation_error')->nullable()->after('creation_log')
                  ->comment('Error message if creation failed');
            
            // Index for querying by status
            $table->index('status');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('sites', function (Blueprint $table) {
            $table->dropColumn(['creation_pid', 'creation_log', 'creation_error']);
            $table->dropIndex(['status']);
        });
    }
};
