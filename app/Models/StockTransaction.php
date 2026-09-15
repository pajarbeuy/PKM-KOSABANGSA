<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class StockTransaction extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = ['user_id', 'type', 'amount', 'notes', 'reference', 'balance_after', 'date'];

    protected $casts = [
        'date' => 'datetime',
        'amount' => 'decimal:2',
        'balance_after' => 'decimal:2',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public static function getCurrentBalance($userId = null)
    {
        $query = self::query();
        if ($userId) {
            $query->where('user_id', $userId);
        }
        $latest = $query->latest('date')->first();
        return $latest?->balance_after ?? 0;
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
