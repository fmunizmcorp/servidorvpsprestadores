<?php

/**
 * SPRINT57 v3.5: Additional routes for async site creation
 * 
 * ADD THESE ROUTES TO /opt/webserver/admin-panel/routes/web.php
 * Inside the auth middleware group
 */

// API endpoint to get site status (for polling)
Route::get('/api/sites/{id}/status', [SitesController::class, 'getStatus'])
    ->name('sites.status');

// API endpoint for callback from wrapper script
Route::post('/api/sites/callback', [SitesController::class, 'callback'])
    ->name('sites.callback')
    ->withoutMiddleware([\App\Http\Middleware\VerifyCsrfToken::class]); // Allow external calls
