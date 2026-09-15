<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateSeasonRequest extends FormRequest
{
    public function authorize()
    {
        return true;
    }

    public function rules()
    {
        return [
            'name' => 'sometimes|required|string|max:255',
            'start_date' => 'sometimes|required|date',
            'end_date' => 'sometimes|required|date|after:start_date',
            'status' => 'sometimes|required|in:active,completed,cancelled',
            'notes' => 'nullable|string|max:1000',
        ];
    }

    public function messages()
    {
        return [
            'name.required' => 'Nama musim tanam harus diisi.',
            'name.max' => 'Nama musim tanam maksimal 255 karakter.',
            'start_date.required' => 'Tanggal mulai harus diisi.',
            'end_date.required' => 'Tanggal selesai harus diisi.',
            'end_date.after' => 'Tanggal selesai harus setelah tanggal mulai.',
            'status.required' => 'Status harus dipilih.',
            'status.in' => 'Status hanya boleh aktif, selesai, atau dibatalkan.',
        ];
    }
}
