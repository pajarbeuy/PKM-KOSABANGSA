<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Carbon;

class Season extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = ['user_id', 'name', 'start_date', 'end_date', 'status', 'target_kg'];

    protected $casts = [
        'start_date' => 'date',
        'end_date' => 'date',
    ];

    protected $appends = ['computed_status'];

    public function getComputedStatusAttribute(): string
    {
        return $this->computeStatus();
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function harvests()
    {
        return $this->hasMany(Harvest::class);
    }

    public function costs()
    {
        return $this->hasMany(ProductionCost::class);
    }

    public function totalHarvest()
    {
        return $this->harvests()->sum('weight_kg');
    }

    public function totalCost()
    {
        return $this->costs()->sum('amount');
    }

    public function computeStatus(): string
    {
        $currentStatus = $this->getRawOriginal('status') ?? $this->status;
        if ($currentStatus === 'cancelled') {
            return 'cancelled';
        }

        if (!$this->start_date || !$this->end_date) {
            return $currentStatus ?? 'active';
        }

        $today = Carbon::today();
        if ($today->lt($this->start_date)) {
            return 'belum_dimulai';
        }
        if ($today->gt($this->end_date)) {
            return 'completed';
        }
        return 'active';
    }
}

