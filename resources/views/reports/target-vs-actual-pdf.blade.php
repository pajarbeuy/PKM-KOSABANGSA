<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
    <title>Laporan Target vs Realisasi</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: DejaVu Sans, sans-serif;
            font-size: 11px;
            color: #222;
            background: #fff;
        }
        .header {
            background: #1B5E20;
            color: white;
            padding: 20px 24px;
            border-radius: 4px;
            margin-bottom: 20px;
        }
        .header h1 { font-size: 20px; margin-bottom: 4px; }
        .header p { font-size: 11px; color: #A5D6A7; }
        .meta-table { width: 100%; margin-bottom: 20px; }
        .meta-table td { padding: 3px 6px; font-size: 11px; }
        .meta-table td:first-child { color: #555; width: 140px; }

        .section-title {
            font-size: 13px;
            font-weight: bold;
            color: #1B5E20;
            border-bottom: 2px solid #1B5E20;
            padding-bottom: 5px;
            margin-bottom: 10px;
        }
        .section-desc {
            font-size: 10px;
            color: #666;
            margin-bottom: 16px;
        }

        table.data-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 16px;
            font-size: 10px;
        }
        table.data-table thead th {
            background: #E8F5E9;
            color: #1B5E20;
            padding: 8px 10px;
            text-align: left;
            font-weight: bold;
            border: 1px solid #C8E6C9;
        }
        table.data-table tbody td {
            padding: 8px 10px;
            border: 1px solid #e0e0e0;
            vertical-align: middle;
        }
        table.data-table tbody tr:nth-child(even) td {
            background: #F9FBE7;
        }
        .text-right { text-align: right; }
        .text-center { text-align: center; }

        .progress-wrap {
            background: #f0f0f0;
            border-radius: 6px;
            height: 10px;
            width: 100%;
            overflow: hidden;
        }
        .progress-bar {
            height: 10px;
            border-radius: 6px;
        }
        .bar-success { background: #27AE60; }
        .bar-warning { background: #F39C12; }
        .bar-danger  { background: #EB5757; }

        .badge {
            display: inline-block;
            padding: 3px 10px;
            border-radius: 10px;
            font-size: 9px;
            font-weight: bold;
        }
        .badge-success { background: #E8F5E9; color: #27AE60; }
        .badge-warning { background: #FFF8E1; color: #F39C12; }
        .badge-danger  { background: #FFEBEE; color: #EB5757; }

        .summary-row {
            margin-bottom: 20px;
        }
        .summary-cards { width: 100%; border-collapse: collapse; margin-bottom: 20px; }
        .summary-cards td { padding: 12px 16px; border: 1px solid #e0e0e0; }
        .card-label { font-size: 10px; color: #888; font-weight: bold; text-transform: uppercase; letter-spacing: 0.5px; }
        .card-value { font-size: 18px; font-weight: bold; margin-top: 4px; }
        .card-green .card-value { color: #27AE60; }
        .card-orange .card-value { color: #F39C12; }
        .card-blue .card-value { color: #2D9CDB; }

        .footer {
            margin-top: 30px;
            border-top: 1px solid #e0e0e0;
            padding-top: 10px;
            font-size: 9px;
            color: #aaa;
            text-align: center;
        }
    </style>
</head>
<body>

<div class="header">
    <h1>🌿 Laporan Target vs Realisasi Panen</h1>
    <p>{{ $user->farm_name ?? $user->name }} &bull; Dicetak pada {{ now()->format('d M Y, H:i') }}</p>
</div>

<table class="meta-table">
    <tr>
        <td>Petani / Kelompok</td>
        <td>: <strong>{{ $user->name }}</strong></td>
    </tr>
    <tr>
        <td>Email</td>
        <td>: {{ $user->email }}</td>
    </tr>
    <tr>
        <td>Tanggal Cetak</td>
        <td>: {{ now()->format('d F Y') }}</td>
    </tr>
    <tr>
        <td>Jumlah Musim</td>
        <td>: {{ count($data) }} musim tanam</td>
    </tr>
</table>

{{-- Summary Stats --}}
@php
    $totalSukses  = count(array_filter($data, fn($d) => $d['percentage'] >= 100));
    $totalHampir  = count(array_filter($data, fn($d) => $d['percentage'] >= 70 && $d['percentage'] < 100));
    $totalKurang  = count(array_filter($data, fn($d) => $d['percentage'] < 70));
@endphp

<table class="summary-cards">
    <tr>
        <td class="card-green">
            <div class="card-label">Tercapai (≥100%)</div>
            <div class="card-value">{{ $totalSukses }} musim</div>
        </td>
        <td class="card-orange">
            <div class="card-label">Hampir Tercapai (70-99%)</div>
            <div class="card-value">{{ $totalHampir }} musim</div>
        </td>
        <td>
            <div class="card-label" style="color:#888;">Kurang (<70%)</div>
            <div class="card-value" style="color:#EB5757;">{{ $totalKurang }} musim</div>
        </td>
    </tr>
</table>

<div class="section-title">Rincian Realisasi per Musim Tanam</div>
<div class="section-desc">Perbandingan bobot panen aktual terhadap target awal yang ditetapkan.</div>

@if(count($data) > 0)
<table class="data-table">
    <thead>
        <tr>
            <th>#</th>
            <th>Nama Musim Tanam</th>
            <th class="text-right">Target (kg)</th>
            <th class="text-right">Aktual (kg)</th>
            <th class="text-right">Selisih (kg)</th>
            <th class="text-center">Realisasi</th>
            <th class="text-center">Status</th>
        </tr>
    </thead>
    <tbody>
        @foreach($data as $i => $item)
        @php
            $selisih = $item['actual'] - $item['target'];
            $badgeClass = $item['percentage'] >= 100 ? 'badge-success' : ($item['percentage'] >= 70 ? 'badge-warning' : 'badge-danger');
            $barClass   = $item['percentage'] >= 100 ? 'bar-success' : ($item['percentage'] >= 70 ? 'bar-warning' : 'bar-danger');
            $width      = min($item['percentage'], 100);
        @endphp
        <tr>
            <td class="text-center">{{ $i + 1 }}</td>
            <td><strong>{{ $item['season'] }}</strong></td>
            <td class="text-right">{{ number_format($item['target'], 0, ',', '.') }}</td>
            <td class="text-right">{{ number_format($item['actual'], 0, ',', '.') }}</td>
            <td class="text-right" style="color:{{ $selisih >= 0 ? '#27AE60' : '#EB5757' }}">
                {{ $selisih >= 0 ? '+' : '' }}{{ number_format($selisih, 0, ',', '.') }}
            </td>
            <td>
                <div class="progress-wrap">
                    <div class="progress-bar {{ $barClass }}" style="width:{{ $width }}%;"></div>
                </div>
                <div style="text-align:center; font-size:9px; margin-top:2px; font-weight:bold;">{{ number_format($item['percentage'], 1) }}%</div>
            </td>
            <td class="text-center">
                <span class="badge {{ $badgeClass }}">{{ $item['status'] }}</span>
            </td>
        </tr>
        @endforeach
    </tbody>
</table>
@else
<p style="color:#888; padding: 20px; text-align: center;">Belum ada data musim tanam terdaftar.</p>
@endif

<div class="footer">
    Laporan ini digenerate otomatis oleh sistem Pertanian Kentang &bull; {{ now()->format('d M Y H:i:s') }}
</div>

</body>
</html>
