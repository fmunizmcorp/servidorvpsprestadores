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
        Schema::create('email_accounts', function (Blueprint $table) {
            $table->id();
            $table->string('email')->unique()->comment('Endereço de email completo (ex: user@example.com)');
            $table->string('domain')->comment('Domínio de email (ex: example.com)');
            $table->string('username')->comment('Nome de usuário (parte antes do @)');
            $table->integer('quota_mb')->default(1000)->comment('Cota de armazenamento em MB');
            $table->integer('used_mb')->default(0)->comment('Espaço usado em MB');
            $table->enum('status', ['active', 'suspended', 'inactive'])->default('active')->comment('Status da conta');
            $table->timestamp('last_login')->nullable()->comment('Data do último login');
            $table->timestamps();
            
            // Indexes
            $table->index('email');
            $table->index('domain');
            $table->index('username');
            $table->index('status');
            
            // Foreign key
            $table->foreign('domain')
                  ->references('domain')
                  ->on('email_domains')
                  ->onDelete('cascade')
                  ->onUpdate('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('email_accounts');
    }
};
