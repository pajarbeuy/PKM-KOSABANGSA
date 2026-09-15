<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Harvest extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = ['user_id', 'season_id', 'quantity', 'date', 'weight_kg', 'notes', 'photo', 'status'];

    protected $casts = [
        'date' => 'date',
        'weight_kg' => 'decimal:2',
    ];

    protected $with = ['season'];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function season()
    {
        return $this->belongsTo(Season::class);
    }
}
