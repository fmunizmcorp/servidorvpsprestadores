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
        Schema::create('email_domains', function (Blueprint $table) {
            $table->id();
            $table->string('domain')->unique()->comment('Domínio de email (ex: example.com)');
            $table->enum('status', ['active', 'suspended', 'inactive'])->default('active')->comment('Status do domínio');
            $table->string('dkim_selector')->default('mail')->comment('Seletor DKIM (ex: mail)');
            $table->text('dkim_public_key')->nullable()->comment('Chave pública DKIM');
            $table->text('dkim_private_key')->nullable()->comment('Chave privada DKIM');
            $table->text('mx_record')->nullable()->comment('Registro MX');
            $table->text('spf_record')->nullable()->comment('Registro SPF');
            $table->text('dmarc_record')->nullable()->comment('Registro DMARC');
            $table->timestamps();
            
            // Indexes
            $table->index('domain');
            $table->index('status');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('email_domains');
    }
};
