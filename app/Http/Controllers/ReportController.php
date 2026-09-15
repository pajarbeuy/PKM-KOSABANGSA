<?php

namespace App\Http\Controllers;

use App\Exports\ProfitLossExport;
use App\Exports\TargetVsActualExport;
use App\Services\ReportService;
use App\Traits\ApiResponseTrait;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Maatwebsite\Excel\Facades\Excel;

class ReportController extends Controller
{
    use ApiResponseTrait;

    public function __construct(private readonly ReportService $reportService) {}

    public function profitLoss(Request $request)
    {
        $data = $this->reportService->getProfitLoss(
            $request->user()->id,
            $request->query('season_id')
        );

        return $this->successResponse($data, 'Laporan laba rugi berhasil diambil.');
    }

    public function targetVsActual(Request $request)
    {
        $data = $this->reportService->getTargetVsActual($request->user()->id);
        return $this->successResponse($data, 'Laporan target vs realisasi berhasil diambil.');
    }

    public function exportProfitLossExcel(Request $request)
    {
        try {
            $export   = $this->reportService->getProfitLossForExport(
                $request->user()->id,
                $request->query('season_id')
            );
            $filename = 'Laporan_Laba_Rugi_' . now()->format('Y-m-d_His') . '.xlsx';

            return Excel::download(
                new ProfitLossExport($export['sales'], $export['costs'], $request->user(), $export['totalRevenue'], $export['totalCost']),
                $filename
            );
        } catch (\Exception $e) {
            return $this->errorResponse('Gagal mengexport laporan: ' . $e->getMessage(), 400);
        }
    }

    public function exportProfitLossPdf(Request $request)
    {
        try {
            $export = $this->reportService->getProfitLossForExport(
                $request->user()->id,
                $request->query('season_id')
            );
            $profit = $export['totalRevenue'] - $export['totalCost'];

            $pdf = Pdf::loadView('reports.profit-loss-pdf', [
                'user'         => $request->user(),
                'totalRevenue' => $export['totalRevenue'],
                'totalCost'    => $export['totalCost'],
                'profit'       => $profit,
                'sales'        => $export['sales'],
                'costs'        => $export['costs'],
            ]);

            return $pdf->download('Laporan_Laba_Rugi_' . now()->format('Y-m-d_His') . '.pdf');
        } catch (\Exception $e) {
            Log::error('PDF Export Error (Profit-Loss): ' . $e->getMessage() . ' | ' . $e->getTraceAsString());
            return $this->errorResponse('Gagal mengexport laporan: ' . $e->getMessage(), 500);
        }
    }

    public function exportTargetVsActualExcel(Request $request)
    {
        try {
            $data     = $this->reportService->getTargetVsActualForExport($request->user()->id, false);
            $filename = 'Laporan_Target_vs_Realisasi_' . now()->format('Y-m-d_His') . '.xlsx';

            return Excel::download(new TargetVsActualExport($data, $request->user()), $filename);
        } catch (\Exception $e) {
            return $this->errorResponse('Gagal mengexport laporan: ' . $e->getMessage(), 400);
        }
    }

    public function exportTargetVsActualPdf(Request $request)
    {
        try {
            $data = $this->reportService->getTargetVsActualForExport($request->user()->id, true);

            $pdf = Pdf::loadView('reports.target-vs-actual-pdf', [
                'user' => $request->user(),
                'data' => $data,
            ]);

            return $pdf->download('Laporan_Target_vs_Realisasi_' . now()->format('Y-m-d_His') . '.pdf');
        } catch (\Exception $e) {
            Log::error('PDF Export Error (Target-vs-Actual): ' . $e->getMessage() . ' | ' . $e->getTraceAsString());
            return $this->errorResponse('Gagal mengexport laporan: ' . $e->getMessage(), 500);
        }
    }
}
