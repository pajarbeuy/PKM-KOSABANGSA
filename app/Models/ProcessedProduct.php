<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class ProcessedProduct extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'owner_id',
        'harvest_id',
        'name',
        'price',
        'stock',
        'raw_material_weight_kg',
        'unit',
        'description',
        'photo',
        'status',
    ];

    protected $casts = [
        'price'                  => 'decimal:2',
        'stock'                  => 'integer',
        'raw_material_weight_kg' => 'decimal:2',
    ];

    protected $appends = [
        'photo_url',
        'total_processing_cost',
        'total_sales_revenue',
        'profit_loss',
    ];

    protected static function booted(): void
    {
        static::saving(function (ProcessedProduct $product) {
            if ($product->stock < 0) {
                throw new \InvalidArgumentException('Stok produk olahan tidak boleh negatif.');
            }

            // State machine rules:
            // 1. If stock is 0, auto-transition to out_of_stock unless manually set to inactive
            if ($product->stock === 0) {
                if ($product->status !== 'inactive') {
                    $product->status = 'out_of_stock';
                }
            } else {
                // 2. If stock > 0 and status was out_of_stock, auto-transition to active
                if ($product->status === 'out_of_stock' || empty($product->status)) {
                    $product->status = 'active';
                }
            }
        });
    }

    public function owner()
    {
        return $this->belongsTo(User::class, 'owner_id');
    }

    public function rawMaterialHarvest()
    {
        return $this->belongsTo(Harvest::class, 'harvest_id');
    }

    public function costs()
    {
        return $this->hasMany(ProductionCost::class, 'processed_product_id');
    }

    public function sales()
    {
        return $this->hasMany(Sale::class, 'processed_product_id');
    }

    public function getTotalProcessingCostAttribute(): float
    {
        return (float) ($this->relationLoaded('costs') ? $this->costs->sum('amount') : $this->costs()->sum('amount'));
    }

    public function getTotalSalesRevenueAttribute(): float
    {
        $paidSales = $this->relationLoaded('sales')
            ? $this->sales->where('payment_status', 'paid')
            : $this->sales()->where('payment_status', 'paid')->get();

        return (float) $paidSales->sum('total');
    }

    public function getProfitLossAttribute(): float
    {
        return round($this->total_sales_revenue - $this->total_processing_cost, 2);
    }

    /**
     * Scope for public catalog: displays both active and out_of_stock products.
     * Inactive products are hidden.
     */
    public function scopeForCatalog($query)
    {
        return $query->whereIn('status', ['active', 'out_of_stock']);
    }

    public function scopeActive($query)
    {
        return $query->where('status', 'active');
    }

    public function getPhotoUrlAttribute(): ?string
    {
        if (!$this->photo) {
            return null;
        }

        if (str_starts_with($this->photo, 'http://') || str_starts_with($this->photo, 'https://')) {
            return $this->photo;
        }

        // Dynamically resolve request host & port if request is active
        try {
            if (app()->bound('request') && request() && request()->hasHeader('host')) {
                return request()->schemeAndHttpHost() . '/storage/' . ltrim($this->photo, '/');
            }
        } catch (\Throwable $e) {
            // Fallback to asset() below
        }

        return asset('storage/' . ltrim($this->photo, '/'));
    }
}
