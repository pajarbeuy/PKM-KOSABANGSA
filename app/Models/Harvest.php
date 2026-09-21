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

    protected $appends = ['photo_url'];

    public function getPhotoUrlAttribute(): ?string
    {
        if (!$this->photo) {
            return null;
        }

        if (str_starts_with($this->photo, 'http://') || str_starts_with($this->photo, 'https://')) {
            return $this->photo;
        }

        try {
            if (app()->bound('request') && request() && request()->hasHeader('host')) {
                return request()->schemeAndHttpHost() . '/' . ltrim($this->photo, '/');
            }
        } catch (\Throwable $e) {}

        return asset(ltrim($this->photo, '/'));
    }

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
