<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class FarmerCommodity extends Model
{
    use HasFactory, SoftDeletes;

    protected $table = 'farmer_commodities';

    protected $fillable = [
        'user_id',
        'name',
        'code',
        'unit',
        'description',
        'status',
    ];

    /**
     * Scope query to only active commodities.
     */
    public function scopeActive($query)
    {
        return $query->where('status', 'active');
    }

    /**
     * Scope query for a specific farmer.
     */
    public function scopeForUser($query, int $userId)
    {
        return $query->where('user_id', $userId);
    }

    /**
     * Owner (farmer) of the commodity.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    /**
     * Harvests associated with this commodity.
     */
    public function harvests(): HasMany
    {
        return $this->hasMany(Harvest::class, 'commodity_id');
    }

    /**
     * Planting seasons associated with this commodity.
     */
    public function seasons(): HasMany
    {
        return $this->hasMany(Season::class, 'commodity_id');
    }
}
