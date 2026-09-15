<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class ProductionCost extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = ['user_id', 'date', 'season_id', 'category', 'amount', 'notes'];

    protected $casts = [
        'date' => 'date',
        'amount' => 'decimal:2',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function season()
    {
        return $this->belongsTo(Season::class);
    }

    public static function getTotalCost($userId = null)
    {
        $query = self::query();
        if ($userId) {
            $query->where('user_id', $userId);
        }
        return $query->sum('amount');
    }

    public static function getCostByCategory($userId = null)
    {
        $query = self::query();
        if ($userId) {
            $query->where('user_id', $userId);
        }
        return $query->groupBy('category')->selectRaw('category, SUM(amount) as total')->get();
    }
}
