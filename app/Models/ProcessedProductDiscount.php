<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ProcessedProductDiscount extends Model
{
    use HasFactory;

    protected $fillable = [
        'processed_product_id',
        'discount_percentage',
        'start_date',
        'end_date',
        'created_by',
    ];

    protected $casts = [
        'discount_percentage' => 'decimal:2',
        'start_date'          => 'date:Y-m-d',
        'end_date'            => 'date:Y-m-d',
    ];

    public function processedProduct(): BelongsTo
    {
        return $this->belongsTo(ProcessedProduct::class, 'processed_product_id');
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    /**
     * Scope for active discounts on a given date (defaults to today).
     */
    public function scopeActive($query, ?string $date = null)
    {
        $targetDate = $date ?: now()->toDateString();
        return $query->whereDate('start_date', '<=', $targetDate)
                     ->whereDate('end_date', '>=', $targetDate);
    }
}
