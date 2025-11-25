<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

/**
 * Users Controller - SPRINT 37
 * Gerenciamento de usuários do admin panel
 */
class UsersController extends Controller
{
    /**
     * Display users listing
     */
    public function index()
    {
        // TODO: Buscar usuários do banco de dados
        // Por enquanto, retorna mock data
        $users = $this->getAllUsers();
        
        return view('users.index', [
            'users' => $users
        ]);
    }
    
    /**
     * Show form to create new user
     */
    public function create()
    {
        $roles = ['admin', 'user', 'viewer'];
        
        return view('users.create', [
            'roles' => $roles
        ]);
    }
    
    /**
     * Store new user
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|email|max:255|unique:users',
            'password' => 'required|string|min:8|confirmed',
            'role' => 'required|in:admin,user,viewer'
        ]);
        
        if ($validator->fails()) {
            return redirect()->back()
                ->withErrors($validator)
                ->withInput();
        }
        
        try {
            // TODO: Criar usuário real no banco de dados
            /*
            $user = User::create([
                'name' => $request->name,
                'email' => $request->email,
                'password' => Hash::make($request->password),
                'role' => $request->role,
            ]);
            */
            
            return redirect()->route('users.index')
                ->with('success', "User created successfully!");
                
        } catch (\Exception $e) {
            return redirect()->back()
                ->with('error', 'Failed to create user: ' . $e->getMessage())
                ->withInput();
        }
    }
    
    /**
     * Show form to edit user
     */
    public function edit($id)
    {
        $roles = ['admin', 'user', 'viewer'];
        
        // TODO: Buscar usuário real
        $user = $this->getUserById($id);
        
        return view('users.edit', [
            'user' => $user,
            'roles' => $roles
        ]);
    }
    
    /**
     * Update user
     */
    public function update(Request $request, $id)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|email|max:255',
            'password' => 'nullable|string|min:8|confirmed',
            'role' => 'required|in:admin,user,viewer'
        ]);
        
        if ($validator->fails()) {
            return redirect()->back()
                ->withErrors($validator)
                ->withInput();
        }
        
        try {
            // TODO: Atualizar usuário real
            
            return redirect()->route('users.index')
                ->with('success', "User updated successfully!");
                
        } catch (\Exception $e) {
            return redirect()->back()
                ->with('error', 'Failed to update user: ' . $e->getMessage())
                ->withInput();
        }
    }
    
    /**
     * Delete user
     */
    public function destroy($id)
    {
        try {
            // TODO: Deletar usuário real
            // Não permitir deletar o próprio usuário
            
            return redirect()->route('users.index')
                ->with('success', "User deleted successfully!");
                
        } catch (\Exception $e) {
            return redirect()->back()
                ->with('error', 'Failed to delete user: ' . $e->getMessage());
        }
    }
    
    // ========== HELPER METHODS ==========
    
    /**
     * Get all users
     * TODO: Buscar do banco de dados
     */
    private function getAllUsers()
    {
        // Mock data
        return [
            [
                'id' => 1,
                'name' => 'Admin User',
                'email' => 'admin@example.com',
                'role' => 'admin',
                'created_at' => now()->subDays(30),
                'last_login' => now()->subHours(2),
            ],
            [
                'id' => 2,
                'name' => 'Test User',
                'email' => 'test@admin.local',
                'role' => 'admin',
                'created_at' => now()->subDays(10),
                'last_login' => now()->subMinutes(5),
            ],
        ];
    }
    
    /**
     * Get user by ID
     * TODO: Buscar do banco de dados
     */
    private function getUserById($id)
    {
        // Mock data
        return [
            'id' => $id,
            'name' => 'Test User',
            'email' => 'test@admin.local',
            'role' => 'admin',
        ];
    }
}
