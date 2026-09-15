<?php

namespace App\Services;

use App\Models\StockTransaction;

class StockService
{
    /**
     * Get the current stock balance for a user.
     */
    public function getCurrentBalance(int $userId): float
    {
        return StockTransaction::getCurrentBalance($userId);
    }

    /**
     * Check if a withdrawal amount is valid given current stock.
     */
    public function hasSufficientStock(float $amount, int $userId): bool
    {
        return $this->getCurrentBalance($userId) >= $amount;
    }

    /**
     * Record an incoming stock transaction.
     */
    public function addIncoming(float $amount, string $notes, int $userId): StockTransaction
    {
        return StockTransaction::addTransaction('in', $amount, $notes, null, $userId);
    }

    /**
     * Record an outgoing stock transaction.
     */
    public function addOutgoing(float $amount, string $notes, int $userId): StockTransaction
    {
        return StockTransaction::addTransaction('out', $amount, $notes, null, $userId);
    }

    /**
     * Delete a transaction and rebuild running balances.
     */
    public function deleteTransaction(StockTransaction $transaction, int $userId): void
    {
        $transaction->delete();
        StockTransaction::rebuildBalances($userId);
    }

    /**
     * Format a transaction for API response.
     */
    public function formatTransaction(StockTransaction $transaction): array
    {
        return [
            'id'               => $transaction->id,
            'type'             => $transaction->type,
            'amount'           => $transaction->amount,
            'balance_after'    => $transaction->balance_after,
            'notes'            => $transaction->notes,
            'date'             => $transaction->date,
            'created_at'       => $transaction->created_at,
        ];
    }
}
