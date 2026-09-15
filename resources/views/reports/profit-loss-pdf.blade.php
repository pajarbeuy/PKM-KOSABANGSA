<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
    <title>Laporan Laba Rugi</title>
    <style>
        @page {
            size: A4;
            margin: 15mm 12mm 15mm 12mm;
        }
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: DejaVu Sans, sans-serif;
            font-size: 11px;
            color: #222;
            background: #fff;
            padding: 4mm 0;
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
        .summary-row {
            display: block;
            margin-bottom: 20px;
        }
        .summary-cards { width: 100%; border-collapse: collapse; margin-bottom: 20px; table-layout: fixed; }
        .summary-cards td { padding: 14px 16px; border: 1px solid #e0e0e0; vertical-align: top; border-radius: 4px; width:33%; }
        .summary-cards .card-label { font-size: 10px; color: #888; font-weight: bold; text-transform: uppercase; letter-spacing: 0.5px; }
        .summary-cards .card-value { font-size: 16px; font-weight: bold; margin-top: 4px; }
        .card-green .card-value { color: #27AE60; }
        .card-red .card-value { color: #EB5757; }
        .card-blue .card-value { color: #2D9CDB; }

        .profit-box {
            padding: 16px 20px;
            border-radius: 4px;
            margin-bottom: 20px;
            text-align: center;
        }
        .profit-box.profit { background: #1B5E20; color: white; }
        .profit-box.loss { background: #B71C1C; color: white; }
        .profit-box .label { font-size: 11px; letter-spacing: 1px; text-transform: uppercase; opacity: 0.8; }
        .profit-box .amount { font-size: 24px; font-weight: bold; margin-top: 6px; }

        .section-title {
            font-size: 13px;
            font-weight: bold;
            color: #1B5E20;
            border-bottom: 2px solid #1B5E20;
            padding-bottom: 5px;
            margin-bottom: 10px;
            margin-top: 20px;
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
            padding: 7px 10px;
            border: 1px solid #e0e0e0;
            vertical-align: top;
        }
        table.data-table tbody tr:nth-child(even) td {
            background: #F9FBE7;
        }
        .text-right { text-align: right; }
        .text-center { text-align: center; }
        .badge {
            display: inline-block;
            padding: 2px 8px;
            border-radius: 10px;
            font-size: 9px;
            font-weight: bold;
        }
        .badge-success { background: #E8F5E9; color: #27AE60; }
        .badge-danger { background: #FFEBEE; color: #EB5757; }
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
    <h1>🌿 Laporan Laba Rugi</h1>
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
</table>

{{-- Summary Cards --}}
<table class="summary-cards">
    <tr>
        <td class="card-green">
            <div class="card-label">Total Pendapatan</div>
            <div class="card-value">Rp {{ number_format($totalRevenue, 0, ',', '.') }}</div>
        </td>
        <td class="card-red">
            <div class="card-label">Total Biaya Produksi</div>
            <div class="card-value">Rp {{ number_format($totalCost, 0, ',', '.') }}</div>
        </td>
        <td class="{{ $profit >= 0 ? 'card-green' : 'card-red' }}">
            <div class="card-label">{{ $profit >= 0 ? 'Keuntungan Bersih' : 'Kerugian Bersih' }}</div>
            <div class="card-value">Rp {{ number_format(abs($profit), 0, ',', '.') }}</div>
        </td>
    </tr>
</table>

{{-- Profit / Loss Banner --}}
<div class="profit-box {{ $profit >= 0 ? 'profit' : 'loss' }}">
    <div class="label">{{ $profit >= 0 ? 'TOTAL KEUNTUNGAN BERSIH' : 'TOTAL KERUGIAN BERSIH' }}</div>
    <div class="amount">Rp {{ number_format(abs($profit), 0, ',', '.') }}</div>
</div>

{{-- Rincian Penjualan --}}
@if($sales->count() > 0)
<div class="section-title">Rincian Penjualan</div>
<table class="data-table">
    <thead>
        <tr>
            <th>#</th>
            <th>Tanggal</th>
            <th>Pembeli</th>
            <th>Musim Tanam</th>
            <th class="text-right">Harga/kg</th>
            <th class="text-right">Total</th>
        </tr>
    </thead>
    <tbody>
        @foreach($sales as $i => $sale)
        <tr>
            <td class="text-center">{{ $i + 1 }}</td>
            <td>{{ \Carbon\Carbon::parse($sale->sale_date ?? $sale->date)->format('d M Y') }}</td>
            <td>{{ $sale->buyer_name }}</td>
            <td>{{ $sale->season->name ?? '-' }}</td>
            <td class="text-right">Rp {{ number_format($sale->price_per_kg, 0, ',', '.') }}</td>
            <td class="text-right">Rp {{ number_format($sale->total, 0, ',', '.') }}</td>
        </tr>
        @endforeach
        <tr>
            <td colspan="5" class="text-right"><strong>Total Pendapatan</strong></td>
            <td class="text-right"><strong>Rp {{ number_format($totalRevenue, 0, ',', '.') }}</strong></td>
        </tr>
    </tbody>
</table>
@endif

{{-- Rincian Biaya Produksi --}}
@if($costs->count() > 0)
<div class="section-title">Rincian Biaya Produksi</div>
<table class="data-table">
    <thead>
        <tr>
            <th>#</th>
            <th>Tanggal</th>
            <th>Kategori</th>
            <th>Musim Tanam</th>
            <th>Keterangan</th>
            <th class="text-right">Jumlah</th>
        </tr>
    </thead>
    <tbody>
        @foreach($costs as $i => $cost)
        <tr>
            <td class="text-center">{{ $i + 1 }}</td>
            <td>{{ \Carbon\Carbon::parse($cost->date)->format('d M Y') }}</td>
            <td>{{ $cost->category }}</td>
            <td>{{ $cost->season->name ?? '-' }}</td>
            <td>{{ $cost->notes ?? '-' }}</td>
            <td class="text-right">Rp {{ number_format($cost->amount, 0, ',', '.') }}</td>
        </tr>
        @endforeach
        <tr>
            <td colspan="5" class="text-right"><strong>Total Biaya</strong></td>
            <td class="text-right"><strong>Rp {{ number_format($totalCost, 0, ',', '.') }}</strong></td>
        </tr>
    </tbody>
</table>
@endif

<div class="footer">
    Laporan ini digenerate otomatis oleh sistem Pertanian Kentang &bull; {{ now()->format('d M Y H:i:s') }}
</div>

</body>
</html>
