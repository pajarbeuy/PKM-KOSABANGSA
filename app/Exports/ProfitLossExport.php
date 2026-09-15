<?php

namespace App\Exports;

use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithStyles;
use Maatwebsite\Excel\Concerns\WithColumnWidths;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;
use PhpOffice\PhpSpreadsheet\Style\Alignment;
use PhpOffice\PhpSpreadsheet\Style\Border;
use PhpOffice\PhpSpreadsheet\Style\Fill;

class ProfitLossExport implements FromCollection, WithHeadings, WithStyles, WithColumnWidths
{
    protected $sales;
    protected $costs;
    protected $user;
    protected $totalRevenue;
    protected $totalCost;
    protected $profit;

    public function __construct($sales, $costs, $user, $totalRevenue, $totalCost)
    {
        $this->sales = $sales;
        $this->costs = $costs;
        $this->user = $user;
        $this->totalRevenue = $totalRevenue;
        $this->totalCost = $totalCost;
        $this->profit = $totalRevenue - $totalCost;
    }

    public function collection()
    {
        $rows = collect();

        // Header section
        $rows->push(['LAPORAN LABA RUGI']);
        $rows->push(['Petani: ' . $this->user->name]);
        $rows->push(['Nama Farm: ' . ($this->user->farm_name ?? '-')]);
        $rows->push(['Tanggal Export: ' . now('Asia/Jakarta')->format('d-m-Y H:i:s')]);
        $rows->push([]);

        // Summary section
        $rows->push(['RINGKASAN']);
        $rows->push(['Total Pendapatan', 'Rp ' . number_format($this->totalRevenue, 0, ',', '.')]);
        $rows->push(['Total Biaya', 'Rp ' . number_format($this->totalCost, 0, ',', '.')]);
        $rows->push(['Untung / Rugi', 'Rp ' . number_format($this->profit, 0, ',', '.')]);
        $rows->push([]);

        // Sales detail
        $rows->push(['DETAIL PENJUALAN']);
        $rows->push(['Tanggal', 'Pembeli', 'Jumlah (kg)', 'Harga/kg', 'Total']);
        
        foreach ($this->sales as $sale) {
            $rows->push([
                $sale->created_at->format('d-m-Y'),
                $sale->buyer_name,
                $sale->weight_kg,
                'Rp ' . number_format($sale->price_per_kg, 0, ',', '.'),
                'Rp ' . number_format($sale->total, 0, ',', '.')
            ]);
        }

        $rows->push([]);

        // Cost detail
        $rows->push(['DETAIL BIAYA PRODUKSI']);
        $rows->push(['Tanggal', 'Kategori', 'Jumlah', 'Keterangan']);
        
        foreach ($this->costs as $cost) {
            $rows->push([
                $cost->created_at->format('d-m-Y'),
                $cost->category,
                'Rp ' . number_format($cost->amount, 0, ',', '.'),
                $cost->description ?? '-'
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

        $sheet->getStyle('A7:B7')->getFill()->setFillType(Fill::FILL_SOLID)->getStartColor()->setARGB('FFC0C0C0');
        $sheet->getStyle('A7:B7')->getFont()->setBold(true);

        return [];
    }

    public function columnWidths(): array
    {
        return [
            'A' => 20,
            'B' => 25,
            'C' => 15,
            'D' => 15,
            'E' => 15,
        ];
    }
}
