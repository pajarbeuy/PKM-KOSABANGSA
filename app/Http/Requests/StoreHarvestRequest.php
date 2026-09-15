<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreHarvestRequest extends FormRequest
{
    public function authorize()
    {
        return true;
    }

    public function rules()
    {
        return [
            'season_id' => 'required|integer|exists:seasons,id',
            'harvest_date' => 'nullable|date',
            'date' => 'nullable|date',
            'quantity' => 'nullable|integer|min:0',
            'weight_kg' => 'required|numeric|min:0.01',
            'notes' => 'nullable|string|max:1000',
            'status' => 'nullable|in:recorded,verified,cancelled',
        ];
    }

    public function messages()
    {
        return [
            'season_id.required' => 'Musim tanam harus dipilih.',
            'season_id.exists' => 'Musim tanam tidak ditemukan.',
            'weight_kg.required' => 'Berat (kg) harus diisi.',
            'weight_kg.min' => 'Berat minimal 0.01 kg.',
        ];
    }
}
