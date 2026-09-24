<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class StockTransaction extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'user_id',
        'processed_product_id',
        'type',
        'amount',
        'unit',
        'notes',
        'reference',
        'balance_after',
        'date',
    ];

    protected $casts = [
        'date' => 'datetime',
        'amount' => 'decimal:2',
        'balance_after' => 'decimal:2',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function processedProduct()
    {
        return $this->belongsTo(ProcessedProduct::class, 'processed_product_id');
    }

    public static function getCurrentBalance($userId = null)
    {
        // Only calculate raw harvest balance, ignoring processed product records
        $query = self::whereNull('processed_product_id');
        if ($userId) {
            $query->where('user_id', $userId);
        }
        $latest = $query->orderByDesc('date')->orderByDesc('id')->first();
        return (float) ($latest?->balance_after ?? 0);
    }

    /**
     * Record stock transaction audit log for processed product.
     */
    public static function recordProcessedProductTransaction(
        ProcessedProduct $product,
        string $type,
        float $amount,
        ?string $notes = null,
        ?string $reference = null,
        ?int $userId = null
    ): self {
        return self::create([
            'user_id'              => $userId ?? $product->owner_id,
            'processed_product_id' => $product->id,
            'type'                 => $type,
            'amount'               => $amount,
            'unit'                 => $product->unit ?? 'pcs',
            'notes'                => $notes,
            'reference'            => $reference,
            'balance_after'        => (float) $product->stock,
            'date'                 => now(),
        ]);
    }

    public static function addTransaction($type, $amount, $notes = null, $reference = null, $userId = null)
    {
        $userId = $userId ?? auth()->id();
        $oldBalance = self::getCurrentBalance($userId);
        $balance = $oldBalance;
        
        if ($type === 'in') {
            $balance += $amount;
        } else {
            $balance -= $amount;
        }

        $transaction = self::create([
            'user_id' => $userId,
            'type' => $type,
            'amount' => $amount,
            'unit' => 'kg',
            'notes' => $notes,
            'reference' => $reference,
            'balance_after' => $balance,
            'date' => now(),
        ]);

        self::triggerThresholdNotification($userId, $oldBalance, $balance);

        return $transaction;
    }

    protected static function triggerThresholdNotification($userId, $oldBalance, $newBalance)
    {
        $minStock = (int) Setting::get('min_stock', 100);
        $maxStock = (int) Setting::get('max_stock', 5000);
        $notifyLowStock = (bool) Setting::get('notify_low_stock', 1);

        if ($notifyLowStock && $oldBalance > $minStock && $newBalance <= $minStock) {
            Notification::create([
                'user_id' => $userId,
                'type' => 'low_stock',
                'title' => 'Stok rendah',
                'message' => "Stok gudang saat ini $newBalance kg, telah berada di bawah batas minimum $minStock kg.",
            ]);
        }

        if ($oldBalance < $maxStock && $newBalance >= $maxStock) {
            Notification::create([
                'user_id' => $userId,
                'type' => 'high_stock',
                'title' => 'Stok tinggi',
                'message' => "Stok gudang saat ini $newBalance kg, telah mencapai batas maksimum $maxStock kg.",
            ]);
        }
    }

    public static function rebuildBalances($userId = null)
    {
        $query = self::orderBy('date')->orderBy('id');
        if ($userId) {
            $query->where('user_id', $userId);
        }
        $transactions = $query->get();

        $balance = 0;
        foreach ($transactions as $transaction) {
            if ($transaction->type === 'in') {
                $balance += $transaction->amount;
            } else {
                $balance -= $transaction->amount;
            }
            $transaction->update(['balance_after' => $balance]);
        }
    }
}
