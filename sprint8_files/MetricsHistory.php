<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class MetricsHistory extends Model
{
    use HasFactory;

    protected $table = 'metrics_history';
    
    protected $fillable = [
        'cpu_usage',
        'memory_usage',
        'disk_usage',
        'cpu_load_1min',
        'cpu_load_5min',
        'cpu_load_15min'
    ];
    
    protected $casts = [
        'cpu_usage' => 'float',
        'memory_usage' => 'float',
        'disk_usage' => 'float',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];
}
