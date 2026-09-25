<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class ProductionCost extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'user_id',
        'cost_type',
        'date',
        'season_id',
        'processed_product_id',
        'raw_material_harvest_id',
        'raw_material_weight_kg',
        'category',
        'item_name',
        'quantity',
        'unit',
        'price_per_unit',
        'amount',
        'notes',
    ];

    protected $casts = [
        'date'                   => 'date',
        'amount'                 => 'decimal:2',
        'quantity'               => 'decimal:2',
        'price_per_unit'         => 'decimal:2',
        'raw_material_weight_kg' => 'decimal:2',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function season()
    {
        return $this->belongsTo(Season::class);
    }

    public function processedProduct()
    {
        return $this->belongsTo(ProcessedProduct::class, 'processed_product_id');
    }

    public function rawMaterialHarvest()
    {
        return $this->belongsTo(Harvest::class, 'raw_material_harvest_id');
    }

    public function scopeFarm($query)
    {
        return $query->where('cost_type', 'farm');
    }

    public function scopeProcessing($query)
    {
        return $query->where('cost_type', 'processing');
    }

    public static function getTotalCost($userId = null, string $costType = 'farm')
    {
        $query = self::query();
        if ($userId) {
            $query->where('user_id', $userId);
        }
        if ($costType) {
            $query->where('cost_type', $costType);
        }
        return (float) $query->sum('amount');
    }

    public static function getCostByCategory($userId = null, ?string $costType = null)
    {
        $query = self::query();
        if ($userId) {
            $query->where('user_id', $userId);
        }
        if ($costType) {
            $query->where('cost_type', $costType);
        }
        return $query->groupBy('category')->selectRaw('category, SUM(amount) as total')->get();
    }
}
