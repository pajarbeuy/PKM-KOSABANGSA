<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreSaleRequest extends FormRequest
{
    public function authorize()
    {
        return true;
    }

    public function rules()
    {
        return [
            'season_id' => 'nullable|integer|exists:seasons,id',
            'quantity' => 'required_without:weight_kg|numeric|min:0.01',
            'weight_kg' => 'required_without:quantity|numeric|min:0.01',
            'price_per_unit' => 'required_without:price_per_kg|numeric|min:0.01',
            'price_per_kg' => 'required_without:price_per_unit|numeric|min:0.01',
            'sale_date' => 'nullable|date',
            'date' => 'nullable|date',
            'buyer_name' => 'required|string|max:255',
            'buyer_phone' => 'nullable|string|max:20',
            'notes' => 'nullable|string|max:1000',
            'status' => 'nullable|string',
            'payment_status' => 'nullable|in:paid,unpaid',
        ];
    }

    public function messages()
    {
        return [
            'buyer_name.required' => 'Nama pembeli harus diisi.',
            'buyer_name.max' => 'Nama pembeli maksimal 255 karakter.',
        ];
    }
}
