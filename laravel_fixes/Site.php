<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Site extends Model
{
    /**
     * The table associated with the model.
     *
     * @var string
     */
    protected $table = 'sites';

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'site_name',
        'domain',
        'php_version',
        'has_database',
        'database_name',
        'database_user',
        'template',
        'status',
        'disk_usage',
        'bandwidth_usage',
        'last_backup',
        'ssl_enabled',
        'ssl_expires_at',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'has_database' => 'boolean',
        'ssl_enabled' => 'boolean',
        'ssl_expires_at' => 'datetime',
        'last_backup' => 'datetime',
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
