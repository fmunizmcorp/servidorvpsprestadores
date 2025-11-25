<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

/**
 * Settings Controller - SPRINT 37
 * Gerenciamento de configurações do sistema
 */
class SettingsController extends Controller
{
    /**
     * Display settings page
     */
    public function index()
    {
        $settings = $this->getSystemSettings();
        
        return view('settings.index', [
            'settings' => $settings
        ]);
    }
    
    /**
     * Update system settings
     */
    public function update(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'site_name' => 'nullable|string|max:255',
            'site_email' => 'nullable|email',
            'timezone' => 'nullable|string',
            'backup_enabled' => 'nullable|boolean',
            'maintenance_mode' => 'nullable|boolean',
        ]);
        
        if ($validator->fails()) {
            return redirect()->back()
                ->withErrors($validator)
                ->withInput();
        }
        
        try {
            // TODO: Salvar configurações reais
            // Por enquanto, apenas simula sucesso
            
            return redirect()->route('settings.index')
                ->with('success', "Settings updated successfully!");
                
        } catch (\Exception $e) {
            return redirect()->back()
                ->with('error', 'Failed to update settings: ' . $e->getMessage())
                ->withInput();
        }
    }
    
    // ========== HELPER METHODS ==========
    
    /**
     * Get system settings
     * TODO: Buscar do banco de dados ou arquivo de configuração
     */
    private function getSystemSettings()
    {
        return [
            'site_name' => 'VPS Admin Panel',
            'site_email' => 'admin@example.com',
            'timezone' => 'America/Sao_Paulo',
            'backup_enabled' => true,
            'maintenance_mode' => false,
            'php_version' => PHP_VERSION,
            'laravel_version' => app()->version(),
            'server_ip' => '72.61.53.222',
        ];
    }
}
