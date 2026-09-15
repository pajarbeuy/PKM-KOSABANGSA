<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Sale extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = ['user_id', 'season_id', 'date', 'buyer_name', 'buyer_phone', 'buyer_address', 'weight_kg', 'price_per_kg', 'total', 'payment_status', 'notes'];

    protected $casts = [
        'date' => 'date',
        'weight_kg' => 'decimal:2',
        'price_per_kg' => 'decimal:2',
        'total' => 'decimal:2',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function season()
    {
        return $this->belongsTo(Season::class);
    }

    public static function getTotalSales($userId = null)
    {
        $query = self::where('payment_status', 'paid');
        if ($userId) {
            $query->where('user_id', $userId);
        }
        return $query->sum('total');
    }

    public static function getAveragePricePerKg($userId = null)
    {
        $query = self::query();
        if ($userId) {
            $query->where('user_id', $userId);
        }
        return $query->avg('price_per_kg');
    }
}
