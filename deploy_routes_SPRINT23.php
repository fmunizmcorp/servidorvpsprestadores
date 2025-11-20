<?php

/**
 * SPRINT 23 - Deploy Routes Addition
 * 
 * Add these routes to /opt/webserver/admin-panel/routes/web.php
 * Insert INSIDE the middleware(['auth', 'verified'])->group(function () { block
 * 
 * LOCATION: After the Monitoring routes section
 */

// ==========================================
// DEPLOYMENT MANAGEMENT (SPRINT 23)
// ==========================================
Route::prefix('deploy')->name('deploy.')->group(function () {
    Route::get('/', [App\Http\Controllers\DeployController::class, 'index'])->name('index');
    Route::get('/execute', [App\Http\Controllers\DeployController::class, 'execute'])->name('execute');
    Route::get('/status', [App\Http\Controllers\DeployController::class, 'status'])->name('status');
});
