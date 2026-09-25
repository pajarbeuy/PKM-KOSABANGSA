<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Commission extends Model
{
    use HasFactory;

    protected $fillable = [
        'sale_id',
        'order_id',
        'user_id',
        'rate',
        'base_amount',
        'commission_amount',
        'net_farmer_amount',
        'status',
        'notes',
    ];

    protected $casts = [
        'rate'              => 'decimal:2',
        'base_amount'       => 'decimal:2',
        'commission_amount' => 'decimal:2',
        'net_farmer_amount' => 'decimal:2',
    ];

    public const DEFAULT_RATE = 10.00;

    /**
     * Confirmed sale this commission originates from.
     */
    public function sale(): BelongsTo
    {
        return $this->belongsTo(Sale::class);
    }

    /**
     * Parent order if this sale originated from catalog pipeline.
     */
    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    /**
     * The farmer whose product was sold.
     */
    public function farmer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    /**
     * Alias for farmer user.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }
}
