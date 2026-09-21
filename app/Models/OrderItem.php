<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class OrderItem extends Model
{
    use HasFactory;

    protected $fillable = [
        'order_id',
        'processed_product_id',
        'quantity',
        'price_snapshot',
        'subtotal',
    ];

    protected $casts = [
        'quantity'       => 'integer',
        'price_snapshot' => 'decimal:2',
        'subtotal'       => 'decimal:2',
    ];

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function processedProduct(): BelongsTo
    {
        return $this->belongsTo(ProcessedProduct::class, 'processed_product_id');
    }
}
