<?php

use App\Http\Controllers\ProfileController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\SitesController;
use App\Http\Controllers\EmailController;
use App\Http\Controllers\TwoFactorController;
use App\Http\Controllers\BackupsController;
use App\Http\Controllers\SecurityController;
use App\Http\Controllers\MonitoringController;
use App\Http\Controllers\DnsController;
use App\Http\Controllers\UsersController;
use App\Http\Controllers\SettingsController;
use App\Http\Controllers\LogsController;
use App\Http\Controllers\ServicesController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Web Routes - Complete VPS Admin Panel
|--------------------------------------------------------------------------
|
| CRITICAL: Routes defined WITHOUT /admin prefix because NGINX config:
| - Uses "alias /opt/webserver/admin-panel/public/" 
| - This STRIPS the /admin/ prefix before passing to Laravel
| - So Laravel receives "/login" not "/admin/login"
|
*/

Route::get('/', function () {
    return redirect('/dashboard');
});

// Auth routes loaded from auth.php (no prefix needed due to NGINX alias)
require __DIR__.'/auth.php';

// Auth-protected routes
Route::middleware(['auth'])->group(function () {
    
    // Dashboard
    Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');
    Route::get('/dashboard/api/historical-metrics', [DashboardController::class, 'apiHistoricalMetrics'])->name('dashboard.apiHistoricalMetrics');
    
    // Profile Routes (Laravel Breeze default)
    Route::get('/profile', [ProfileController::class, 'edit'])->name('profile.edit');
    Route::patch('/profile', [ProfileController::class, 'update'])->name('profile.update');
    Route::delete('/profile', [ProfileController::class, 'destroy'])->name('profile.destroy');
    
    // ==========================================
    // SITES MANAGEMENT
    // ==========================================
    Route::prefix('sites')->name('sites.')->group(function () {
        Route::get('/', [SitesController::class, 'index'])->name('index');
        Route::get('/create', [SitesController::class, 'create'])->name('create');
        Route::post('/', [SitesController::class, 'store'])->name('store');
        Route::get('/{siteName}', [SitesController::class, 'show'])->name('show');
        Route::get('/{siteName}/edit', [SitesController::class, 'edit'])->name('edit');
        Route::put('/{siteName}', [SitesController::class, 'update'])->name('update');
        Route::delete('/{siteName}', [SitesController::class, 'destroy'])->name('destroy');
        
        // Site Actions
        Route::get('/{siteName}/logs', [SitesController::class, 'logs'])->name('logs');
        Route::post('/{siteName}/restart', [SitesController::class, 'restart'])->name('restart');
        Route::post('/{siteName}/clear-cache', [SitesController::class, 'clearCache'])->name('clearCache');
        
        // SSL Management
        Route::get('/{siteName}/ssl', [SitesController::class, 'ssl'])->name('ssl');
        Route::post('/{siteName}/ssl/generate', [SitesController::class, 'generateSSL'])->name('generateSSL');
        
        // SPRINT 11: SSL Renewal
        Route::post('/{siteName}/ssl/renew', [SitesController::class, 'renewSSL'])->name('renewSSL');
        Route::post('/ssl/renew-all', [SitesController::class, 'renewAllSSL'])->name('renewAllSSL');
    });
    
    // ==========================================
    // EMAIL MANAGEMENT
    // ==========================================
    Route::prefix('email')->name('email.')->group(function () {
        // Email Dashboard
        Route::get('/', [EmailController::class, 'index'])->name('index');
        
        // Domain Management
        Route::get('/domains', [EmailController::class, 'domains'])->name('domains');
        Route::get('/domains/create', [EmailController::class, 'createDomain'])->name('domains.create');
        Route::post('/domains', [EmailController::class, 'storeDomain'])->name('storeDomain');
        
        // SPRINT 2: Email Domain EDIT routes
        
        // SPRINT 3: Email Account EDIT routes
        Route::get('/accounts/{id}/edit', [EmailController::class, 'editAccount'])->name('accounts.edit');
        Route::put('/accounts/{id}', [EmailController::class, 'updateAccount'])->name('accounts.update');
        Route::get('/domains/{id}/edit', [EmailController::class, 'editDomain'])->name('domains.edit');
        Route::put('/domains/{id}', [EmailController::class, 'updateDomain'])->name('domains.update');
        
        Route::delete('/domains/{domain}', [EmailController::class, 'deleteDomain'])->name('deleteDomain');
        
        // Account Management
        Route::get('/accounts', [EmailController::class, 'accounts'])->name('accounts');
        Route::get('/accounts/create', [EmailController::class, 'createAccount'])->name('accounts.create');
        Route::post('/accounts', [EmailController::class, 'storeAccount'])->name('storeAccount');
        Route::delete('/accounts', [EmailController::class, 'deleteAccount'])->name('deleteAccount');
        Route::post('/accounts/change-password', [EmailController::class, 'changePassword'])->name('changePassword');
        Route::post('/accounts/change-quota', [EmailController::class, 'changeQuota'])->name('changeQuota');
        
        // Email Queue
        Route::get('/queue', [EmailController::class, 'queue'])->name('queue');
        Route::post('/queue/flush', [EmailController::class, 'flushQueue'])->name('flushQueue');
        Route::delete('/queue/message', [EmailController::class, 'deleteMessage'])->name('deleteMessage');
        Route::get('/queue/message-details', [EmailController::class, 'messageDetails'])->name('messageDetails');
        
        // Email Logs
        Route::get('/logs', [EmailController::class, 'logs'])->name('logs');
        
        // DNS Verification
        Route::get('/dns', [EmailController::class, 'dns'])->name('dns');
        
        // SPRINT 9: Spam Logs
        Route::get('/spam-logs', [EmailController::class, 'spamLogs'])->name('spam-logs');
        Route::post('/spam-logs/clear', [EmailController::class, 'clearSpamLogs'])->name('spam-logs.clear');
        
        // SPRINT 9: Email Aliases
        Route::get('/aliases', [EmailController::class, 'aliases'])->name('aliases');
        Route::get('/aliases/create', [EmailController::class, 'createAlias'])->name('aliases.create');
        Route::post('/aliases', [EmailController::class, 'storeAlias'])->name('aliases.store');
        Route::delete('/aliases', [EmailController::class, 'deleteAlias'])->name('aliases.delete');
    });
    
    // ==========================================
    // BACKUPS MANAGEMENT
    // ==========================================
    Route::prefix('backups')->name('backups.')->group(function () {
        Route::get('/', [BackupsController::class, 'index'])->name('index');
        Route::get('/list', [BackupsController::class, 'list'])->name('list');
        Route::post('/trigger', [BackupsController::class, 'trigger'])->name('trigger');
        
        // Restore
        Route::get('/restore', [BackupsController::class, 'restore'])->name('restore');
        Route::post('/restore/execute', [BackupsController::class, 'executeRestore'])->name('executeRestore');
        
        // Backup Details & Management
        Route::get('/details', [BackupsController::class, 'details'])->name('details');
        Route::delete('/{snapshotId}', [BackupsController::class, 'delete'])->name('delete');
        Route::get('/logs', [BackupsController::class, 'logs'])->name('logs');
    });
    
    // ==========================================
    // SECURITY MANAGEMENT
    // ==========================================
    Route::prefix('security')->name('security.')->group(function () {
        Route::get('/', [SecurityController::class, 'index'])->name('index');
        
        // Firewall (UFW)
        Route::get('/firewall', [SecurityController::class, 'firewall'])->name('firewall');
        Route::post('/firewall/add-rule', [SecurityController::class, 'addRule'])->name('addRule');
        Route::delete('/firewall/delete-rule', [SecurityController::class, 'deleteRule'])->name('deleteRule');
        
        // Fail2Ban
        Route::get('/fail2ban', [SecurityController::class, 'fail2ban'])->name('fail2ban');
        Route::post('/fail2ban/unban', [SecurityController::class, 'unbanIP'])->name('unbanIP');
        
        // ClamAV
        Route::get('/clamav', [SecurityController::class, 'clamav'])->name('clamav');
        Route::post('/clamav/scan', [SecurityController::class, 'scan'])->name('scan');
    });
    
    // ==========================================
    // MONITORING
    // ==========================================
    Route::prefix('monitoring')->name('monitoring.')->group(function () {
        Route::get('/', [MonitoringController::class, 'index'])->name('index');
        
        // Services
        Route::get('/services', [MonitoringController::class, 'services'])->name('services');
        Route::post('/services/restart', [MonitoringController::class, 'restartService'])->name('restartService');
        
        // Processes
        Route::get('/processes', [MonitoringController::class, 'processes'])->name('processes');
        Route::post('/processes/kill', [MonitoringController::class, 'killProcess'])->name('killProcess');
        
        // Logs
        Route::get('/logs', [MonitoringController::class, 'logs'])->name('logs');
        
        // API Endpoints for AJAX
        Route::get('/api/metrics', [MonitoringController::class, 'apiMetrics'])->name('apiMetrics');
        Route::get('/api/services', [MonitoringController::class, 'apiServices'])->name('apiServices');
    });
    
    // ==========================================
    // DNS MANAGEMENT (Sprint 37)
    // ==========================================
    Route::prefix('dns')->name('dns.')->group(function () {
        Route::get('/', [DnsController::class, 'index'])->name('index');
        Route::get('/create', [DnsController::class, 'create'])->name('create');
        Route::post('/store', [DnsController::class, 'store'])->name('store');
    });
    
    // ==========================================
    // USER MANAGEMENT (Sprint 37)
    // ==========================================
    Route::prefix('users')->name('users.')->group(function () {
        Route::get('/', [UsersController::class, 'index'])->name('index');
        Route::get('/create', [UsersController::class, 'create'])->name('create');
        Route::post('/store', [UsersController::class, 'store'])->name('store');
    });
    
    // ==========================================
    // SYSTEM SETTINGS (Sprint 37)
    // ==========================================
    Route::get('/settings', [SettingsController::class, 'index'])->name('settings.index');
    
    // ==========================================
    // LOGS VIEWER (Sprint 6 & 37)
    // ==========================================
    Route::prefix('logs')->name('logs.')->group(function () {
        Route::get('/', [LogsController::class, 'index'])->name('index');
        Route::post('/clear/{type}', [LogsController::class, 'clear'])->name('clear');
        Route::get('/download/{type}', [LogsController::class, 'download'])->name('download');
    });
    
    // ==========================================
    // SERVICES MONITOR (Sprint 7 & 37)
    // ==========================================
    Route::prefix('services')->name('services.')->group(function () {
        Route::get('/', [ServicesController::class, 'index'])->name('index');
        Route::post('/stop/{service}', [ServicesController::class, 'stop'])->name('stop');
        Route::post('/start/{service}', [ServicesController::class, 'start'])->name('start');
        Route::post('/restart/{service}', [ServicesController::class, 'restart'])->name('restart');
    });
    
    // Two-Factor Authentication Routes
    Route::get('/two-factor', [TwoFactorController::class, 'show'])->name('two-factor.show');
    Route::get('/two-factor/enable', [TwoFactorController::class, 'enable'])->name('two-factor.enable');
    Route::post('/two-factor/confirm', [TwoFactorController::class, 'confirm'])->name('two-factor.confirm');
    Route::post('/two-factor/disable', [TwoFactorController::class, 'disable'])->name('two-factor.disable');
    Route::post('/two-factor/regenerate-codes', [TwoFactorController::class, 'regenerateRecoveryCodes'])->name('two-factor.regenerate-codes');
    
    // 2FA Challenge Routes (no additional auth middleware - used during login)
    Route::get('/two-factor/challenge', [TwoFactorController::class, 'challenge'])->name('two-factor.challenge');
    Route::post('/two-factor/verify', [TwoFactorController::class, 'verify'])->name('two-factor.verify');
});
