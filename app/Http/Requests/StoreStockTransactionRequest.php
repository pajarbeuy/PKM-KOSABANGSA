<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreStockTransactionRequest extends FormRequest
{
    public function authorize()
    {
        return true;
    }

    public function rules()
    {
        return [
            'type' => 'required|in:in,out',
            'quantity' => 'required|integer|min:1',
            'transaction_date' => 'required|date|before_or_equal:today',
            'notes' => 'required|string|max:500',
            'reference' => 'nullable|string|max:100',
        ];
    }

    public function messages()
    {
        return [
            'type.required' => 'Tipe transaksi harus dipilih.',
            'type.in' => 'Tipe transaksi hanya boleh masuk (in) atau keluar (out).',
            'quantity.required' => 'Jumlah harus diisi.',
            'quantity.min' => 'Jumlah minimal 1.',
            'transaction_date.required' => 'Tanggal transaksi harus diisi.',
            'transaction_date.before_or_equal' => 'Tanggal transaksi tidak boleh di masa depan.',
            'notes.required' => 'Catatan harus diisi.',
            'notes.max' => 'Catatan maksimal 500 karakter.',
        ];
    }
}
