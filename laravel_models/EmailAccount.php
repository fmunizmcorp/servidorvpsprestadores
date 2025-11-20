<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class EmailAccount extends Model
{
    /**
     * The table associated with the model.
     *
     * @var string
     */
    protected $table = 'email_accounts';

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'email',
        'domain',
        'username',
        'quota_mb',
        'used_mb',
        'status',
        'last_login',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'quota_mb' => 'integer',
        'used_mb' => 'integer',
        'last_login' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var array<int, string>
     */
    protected $hidden = [];

    /**
     * Get the domain this account belongs to.
     */
    public function emailDomain(): BelongsTo
    {
        return $this->belongsTo(EmailDomain::class, 'domain', 'domain');
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

    /**
     * Get quota usage percentage.
     */
    public function getQuotaUsagePercentageAttribute(): float
    {
        if ($this->quota_mb === 0) {
            return 0;
        }
        return round(($this->used_mb / $this->quota_mb) * 100, 2);
    }
}
