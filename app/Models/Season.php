<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Season extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = ['user_id', 'name', 'start_date', 'end_date', 'status', 'target_kg'];

    protected $casts = [
        'start_date' => 'date',
        'end_date' => 'date',
    ];

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
}
