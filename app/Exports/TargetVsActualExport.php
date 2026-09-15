<?php

namespace App\Exports;

use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithStyles;
use Maatwebsite\Excel\Concerns\WithColumnWidths;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;
use PhpOffice\PhpSpreadsheet\Style\Alignment;
use PhpOffice\PhpSpreadsheet\Style\Fill;

class TargetVsActualExport implements FromCollection, WithHeadings, WithStyles, WithColumnWidths
{
    protected $data;
    protected $user;

    public function __construct($data, $user)
    {
        $this->data = $data;
        $this->user = $user;
    }

    public function collection()
    {
        $rows = collect();

        // Header section
        $rows->push(['LAPORAN TARGET VS REALISASI']);
        $rows->push(['Petani: ' . $this->user->name]);
        $rows->push(['Nama Farm: ' . ($this->user->farm_name ?? '-')]);
        $rows->push(['Tanggal Export: ' . now('Asia/Jakarta')->format('d-m-Y H:i:s')]);
        $rows->push([]);

        // Detail
        $rows->push(['Musim Tanam', 'Target (kg)', 'Realisasi (kg)', 'Pencapaian (%)', 'Status']);
        
        foreach ($this->data as $item) {
            $rows->push([
                $item['season'] ?? $item['season_name'],
                $item['target'],
                $item['actual'],
                $item['percentage'] . '%',
                $item['status'] == 'success' ? 'Tercapai' : ($item['status'] == 'warning' ? 'Hampir' : 'Kurang')
            ]);
        }

        return $rows;
    }

    public function headings(): array
    {
        return [];
    }

    public function styles(Worksheet $sheet)
    {
        $sheet->getStyle('A1')->getFont()->setBold(true)->setSize(14);
        $sheet->getStyle('A1')->getAlignment()->setHorizontal(Alignment::HORIZONTAL_CENTER);

        $sheet->getStyle('A5:E5')->getFill()->setFillType(Fill::FILL_SOLID)->getStartColor()->setARGB('FFC0C0C0');
        $sheet->getStyle('A5:E5')->getFont()->setBold(true);

        return [];
    }

    public function columnWidths(): array
    {
        return [
            'A' => 20,
            'B' => 15,
            'C' => 15,
            'D' => 15,
            'E' => 15,
        ];
    }
}
