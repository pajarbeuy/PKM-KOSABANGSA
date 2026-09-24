<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class FarmerGroup extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'name',
        'code',
        'status',
        'leader_name',
        'village',
        'description',
    ];

    /**
     * Scope query to only include active farmer groups.
     */
    public function scopeActive($query)
    {
        return $query->where('status', 'active');
    }

    /**
     * Members belonging to this farmer group.
     */
    public function members(): HasMany
    {
        return $this->hasMany(User::class, 'farmer_group_id');
    }
}
