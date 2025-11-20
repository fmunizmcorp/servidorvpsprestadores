<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class EmailDomain extends Model
{
    /**
     * The table associated with the model.
     *
     * @var string
     */
    protected $table = 'email_domains';

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'domain',
        'status',
        'dkim_selector',
        'dkim_public_key',
        'dkim_private_key',
        'mx_record',
        'spf_record',
        'dmarc_record',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var array<int, string>
     */
    protected $hidden = [
        'dkim_private_key',
    ];

    /**
     * Get the email accounts for this domain.
     */
    public function emailAccounts(): HasMany
    {
        return $this->hasMany(EmailAccount::class, 'domain', 'domain');
    }

    /**
     * Get the status badge color.
     */
    public function getStatusBadgeAttribute(): string
    {
        return match($this->status) {
            'active' => 'success',
            'suspended' => 'warning',
            'inactive' => 'danger',
            default => 'secondary'
        };
    }
}
