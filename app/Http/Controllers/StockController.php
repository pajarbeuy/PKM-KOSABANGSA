<?php

namespace App\Http\Controllers;

use App\Models\StockTransaction;
use App\Services\StockService;
use App\Traits\ApiResponseTrait;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class StockController extends Controller
{
    use ApiResponseTrait;

    public function __construct(private readonly StockService $stockService) {}

    public function index(Request $request)
    {
        $userId         = $request->user()->id;
        $currentBalance = (int) $this->stockService->getCurrentBalance($userId);
        $totalIncoming  = (int) StockTransaction::where('user_id', $userId)->where('type', 'in')->sum('amount');
        $totalOutgoing  = (int) StockTransaction::where('user_id', $userId)->where('type', 'out')->sum('amount');

        $transactions = StockTransaction::where('user_id', $userId)
            ->latest('date')
            ->get()
            ->map(fn ($t) => [
                'id'               => $t->id,
                'type'             => $t->type,
                'quantity'         => (int) $t->amount,
                'transaction_date' => $t->date,
                'notes'            => $t->notes,
                'reference'        => $t->reference,
                'created_at'       => $t->created_at->toIso8601String(),
            ]);

        return $this->successResponse([
            'totalIncoming' => $totalIncoming,
            'totalOutgoing' => $totalOutgoing,
            'currentStock'  => $currentBalance,
            'transactions'  => $transactions,
        ], 'Status persediaan barang.');
    }

    public function storeIncoming(Request $request)
    {
        try {
            $validated   = $request->validate([
                'amount' => 'required|numeric|min:0.01',
                'notes'  => 'required|string|max:255',
            ]);

            $transaction = $this->stockService->addIncoming($validated['amount'], $validated['notes'], $request->user()->id);

            return $this->successResponse($this->stockService->formatTransaction($transaction), 'Transaksi masuk berhasil dicatat.', 201);
        } catch (ValidationException $e) {
            return $this->validationErrorResponse($e->errors());
        }
    }

    public function storeOutgoing(Request $request)
    {
        try {
            $validated = $request->validate([
                'amount' => 'required|numeric|min:0.01',
                'notes'  => 'required|string|max:255',
            ]);

            if (!$this->stockService->hasSufficientStock($validated['amount'], $request->user()->id)) {
                $balance = $this->stockService->getCurrentBalance($request->user()->id);
                return $this->errorResponse("Stok gudang tidak mencukupi. Sisa stok: {$balance} kg", 422);
            }

            $transaction = $this->stockService->addOutgoing($validated['amount'], $validated['notes'], $request->user()->id);

            return $this->successResponse($this->stockService->formatTransaction($transaction), 'Transaksi keluar berhasil dicatat.', 201);
        } catch (ValidationException $e) {
            return $this->validationErrorResponse($e->errors());
        }
    }

    public function destroyTransaction(Request $request, StockTransaction $transaction)
    {
        if ($transaction->user_id !== $request->user()->id) {
            return $this->forbiddenResponse('Anda tidak berhak menghapus data ini.');
        }

        $this->stockService->deleteTransaction($transaction, $request->user()->id);

        return $this->successResponse(null, 'Transaksi berhasil dihapus.');
    }
}
