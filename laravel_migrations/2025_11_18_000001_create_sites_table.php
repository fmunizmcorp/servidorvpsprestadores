<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('sites', function (Blueprint $table) {
            $table->id();
            $table->string('site_name')->unique()->comment('Nome único do site (usado como identificador)');
            $table->string('domain')->comment('Domínio principal do site');
            $table->string('php_version', 10)->default('8.3')->comment('Versão do PHP (ex: 8.3, 8.2)');
            $table->boolean('has_database')->default(true)->comment('Se o site tem banco de dados');
            $table->string('database_name')->nullable()->comment('Nome do banco de dados');
            $table->string('database_user')->nullable()->comment('Usuário do banco de dados');
            $table->string('template', 50)->default('php')->comment('Template usado (php, laravel, wordpress, etc)');
            $table->enum('status', ['active', 'suspended', 'inactive'])->default('active')->comment('Status do site');
            $table->bigInteger('disk_usage')->default(0)->comment('Uso de disco em bytes');
            $table->bigInteger('bandwidth_usage')->default(0)->comment('Uso de bandwidth em bytes');
            $table->timestamp('last_backup')->nullable()->comment('Data do último backup');
            $table->boolean('ssl_enabled')->default(true)->comment('Se SSL está habilitado');
            $table->timestamp('ssl_expires_at')->nullable()->comment('Data de expiração do certificado SSL');
            $table->timestamps();
            
            // Indexes
            $table->index('site_name');
            $table->index('domain');
            $table->index('status');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('sites');
    }
};
