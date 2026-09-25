<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class MarketPrice extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'commodity_id',
        'price',
        'unit',
        'effective_date',
        'source',
        'notes',
        'created_by',
    ];

    protected $casts = [
        'price'          => 'decimal:2',
        'effective_date' => 'date',
    ];

    public function commodity(): BelongsTo
    {
        return $this->belongsTo(FarmerCommodity::class, 'commodity_id');
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function harvests(): HasMany
    {
        return $this->hasMany(Harvest::class, 'market_price_id');
    }

    /**
     * Memeriksa apakah record harga acuan ini sudah pernah dirujuk oleh pencatatan panen historis.
     */
    public function isReferenced(): bool
    {
        return $this->harvests()->exists();
    }

    /**
     * Scope untuk mencari harga pasar yang berlaku efektif pada tanggal tertentu.
     */
    public function scopeEffectiveForDate($query, int $commodityId, string $date)
    {
        return $query->where('commodity_id', $commodityId)
            ->whereDate('effective_date', '<=', $date)
            ->orderBy('effective_date', 'desc');
    }
}
