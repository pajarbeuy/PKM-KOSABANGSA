<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\SoftDeletes;

class Order extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'order_code',
        'customer_name',
        'customer_phone',
        'customer_address',
        'status',
        'total_amount',
        'notes',
    ];

    protected $casts = [
        'total_amount' => 'decimal:2',
    ];

    /**
     * Allowed order status values.
     */
    public const STATUS_PENDING    = 'pending';
    public const STATUS_CONFIRMED  = 'confirmed';
    public const STATUS_PROCESSING = 'processing';
    public const STATUS_COMPLETED  = 'completed';
    public const STATUS_CANCELLED  = 'cancelled';

    public static function allowedStatuses(): array
    {
        return [
            self::STATUS_PENDING,
            self::STATUS_CONFIRMED,
            self::STATUS_PROCESSING,
            self::STATUS_COMPLETED,
            self::STATUS_CANCELLED,
        ];
    }

    /**
     * Items in this order.
     */
    public function items(): HasMany
    {
        return $this->hasMany(OrderItem::class);
    }

    /**
     * Confirmed sale record (created strictly upon completion).
     */
    public function sale(): HasOne
    {
        return $this->hasOne(Sale::class);
    }

    /**
     * Generate unique human-readable order code.
     * Format: ORD-YYYYMMDD-XXXX
     */
    public static function generateOrderCode(): string
    {
        $datePrefix = 'ORD-' . now()->format('Ymd') . '-';
        $randomSuffix = strtoupper(bin2hex(random_bytes(2))); // 4 hex chars
        $code = $datePrefix . $randomSuffix;

        // Ensure uniqueness
        while (self::where('order_code', $code)->exists()) {
            $randomSuffix = strtoupper(bin2hex(random_bytes(2)));
            $code = $datePrefix . $randomSuffix;
        }

        return $code;
    }
}
