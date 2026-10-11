<?php

namespace App\Services;

use App\Models\Commission;
use App\Models\FarmerCommodity;
use App\Models\FarmerGroup;
use App\Models\Harvest;
use App\Models\MarketPrice;
use App\Models\Order;
use App\Models\ProcessedProduct;
use App\Models\User;

class ChatbotDataQueryService
{
    /**
     * Deteksi intent dan ambil data faktual aktual dari database dengan isolasi hak akses (tenant isolation).
     * Mendukung multi-intent (misal menanyakan stok dan pesanan sekaligus).
     *
     * @param User|null $user
     * @param string $message
     * @param string $roleContext ('farmer' | 'super_admin')
     * @return array ['has_data' => bool, 'intent' => ?string, 'summary' => ?string]
     */
    public function queryFactualData(?User $user, string $message, string $roleContext): array
    {
        if (!$user) {
            return ['has_data' => false, 'intent' => null, 'summary' => null];
        }

        $cleanMsg = strtolower($message);

        if ($roleContext === 'farmer') {
            return $this->queryFarmerData($user, $cleanMsg);
        }

        if ($roleContext === 'super_admin') {
            return $this->querySuperAdminData($user, $cleanMsg);
        }

        return ['has_data' => false, 'intent' => null, 'summary' => null];
    }

    /**
     * Query data faktual milik petani yang sedang login (Strict Tenant Isolation).
     */
    protected function queryFarmerData(User $user, string $message): array
    {
        $summaries = [];
        $intents = [];

        // 1. Intent: Pertanyaan metrik/riwayat hasil panen milik petani
        if ($this->hasAnyPhrase($message, [
            'berapa panen', 'total panen', 'hasil panen saya', 'riwayat panen',
            'catatan panen saya', 'berat panen saya', 'produksi panen saya', 'cek panen'
        ])) {
            $harvestQuery = Harvest::where('user_id', $user->id)
                ->where(function ($q) {
                    $q->whereNull('status')->orWhere('status', '!=', 'cancelled');
                });

            $totalCount = $harvestQuery->count();
            $totalWeight = (float) $harvestQuery->sum('weight_kg');

            if ($totalCount === 0) {
                $summaries[] = "Hasil Panen: Anda belum memiliki catatan panen aktif yang tersimpan di sistem.";
            } else {
                $recent = Harvest::where('user_id', $user->id)
                    ->where(function ($q) {
                        $q->whereNull('status')->orWhere('status', '!=', 'cancelled');
                    })
                    ->with('commodity')
                    ->latest('date')
                    ->take(3)
                    ->get()
                    ->map(function ($h) {
                        $cName = $h->commodity?->name ?? 'Komoditas';
                        $dateStr = $h->date ? $h->date->format('Y-m-d') : '-';
                        return "{$cName} ({$h->weight_kg} kg, tgl {$dateStr})";
                    })
                    ->implode('; ');

                $formattedWeight = number_format($totalWeight, 1, '.', '');
                $summaries[] = "Hasil Panen Anda: Total {$formattedWeight} kg dari {$totalCount} catatan panen aktif (Panen terkini: {$recent}).";
            }
            $intents[] = 'harvest';
        }

        // 2. Intent: Pertanyaan daftar komoditas aktif petani
        if ($this->hasAnyPhrase($message, [
            'komoditas saya', 'tanaman saya', 'daftar komoditas', 'apa komoditas saya',
            'tanaman yang saya daftarkan', 'komoditas yang saya tanam', 'lahan saya'
        ])) {
            $activeCommodities = FarmerCommodity::where('user_id', $user->id)
                ->where('status', 'active')
                ->get(['name', 'unit']);

            if ($activeCommodities->isEmpty()) {
                $summaries[] = "Komoditas: Anda belum memiliki komoditas berstatus aktif yang terdaftar di akun Anda.";
            } else {
                $list = $activeCommodities->map(fn($c) => "{$c->name} ({$c->unit})")->implode(', ');
                $summaries[] = "Komoditas Aktif Anda: {$list}.";
            }
            $intents[] = 'commodity';
        }

        // 3. Intent: Pertanyaan harga acuan pasar resmi terkini (effective_date <= hari ini)
        if ($this->hasAnyPhrase($message, [
            'berapa harga pasar', 'harga acuan pasar', 'harga pasar resmi', 'harga pasar terkini',
            'harga pasar acuan', 'harga komoditas hari ini'
        ])) {
            $today = now()->toDateString();
            $userCommodities = FarmerCommodity::where('user_id', $user->id)
                ->where('status', 'active')
                ->get(['id', 'name', 'unit']);

            if ($userCommodities->isEmpty()) {
                $summaries[] = "Harga Pasar: Anda belum mendaftarkan komoditas aktif sehingga belum ada acuan harga pasar yang dipetakan.";
            } else {
                // Cek apakah pesan menyebut nama komoditas spesifik
                $filteredCommodities = $userCommodities->filter(function ($c) use ($message) {
                    return $this->matchesWord(strtolower($c->name), $message);
                });

                $targetCommodities = $filteredCommodities->isNotEmpty() ? $filteredCommodities : $userCommodities;
                $priceLines = [];

                foreach ($targetCommodities as $comm) {
                    $latestPrice = MarketPrice::where('commodity_id', $comm->id)
                        ->whereDate('effective_date', '<=', $today)
                        ->orderBy('effective_date', 'desc')
                        ->first();

                    if ($latestPrice) {
                        $formattedPrice = number_format((float) $latestPrice->price, 0, ',', '.');
                        $effDate = $latestPrice->effective_date ? $latestPrice->effective_date->format('Y-m-d') : '-';
                        $priceLines[] = "{$comm->name}: Rp {$formattedPrice}/{$comm->unit} (berlaku sejak {$effDate})";
                    } else {
                        $priceLines[] = "{$comm->name}: Belum ada harga acuan resmi yang berlaku hari ini";
                    }
                }

                $summaries[] = "Harga Acuan Pasar Resmi (Efektif per Hari Ini): " . implode('; ', $priceLines) . ".";
            }
            $intents[] = 'market_price';
        }

        // 4. Intent: Pertanyaan produk olahan milik petani sendiri
        if ($this->hasAnyPhrase($message, [
            'produk olahan saya', 'stok olahan saya', 'olahan milik saya', 'daftar produk olahan saya'
        ])) {
            $products = ProcessedProduct::where('owner_id', $user->id)->get();
            if ($products->isEmpty()) {
                $summaries[] = "Produk Olahan: Anda belum memiliki produk olahan yang terdaftar di akun Anda.";
            } else {
                $prodList = $products->map(function ($p) {
                    $formattedPrice = number_format((float) $p->price, 0, ',', '.');
                    return "{$p->name} (stok: {$p->stock} {$p->unit}, harga: Rp {$formattedPrice}, status: {$p->status})";
                })->implode('; ');
                $summaries[] = "Produk Olahan Anda: {$prodList}.";
            }
            $intents[] = 'processed_product';
        }

        if (empty($summaries)) {
            return ['has_data' => false, 'intent' => null, 'summary' => null];
        }

        return [
            'has_data' => true,
            'intent'   => implode(',', $intents),
            'summary'  => "DATA RESMI DATABASE MILIK ANDA:\n• " . implode("\n• ", $summaries),
        ];
    }

    /**
     * Query data faktual platform untuk Super Admin / BUMDes (Platform Level Metrics).
     */
    protected function querySuperAdminData(User $user, string $message): array
    {
        $summaries = [];
        $intents = [];

        // 1. Intent: Metrik/jumlah pesanan katalog
        if ($this->hasAnyPhrase($message, [
            'berapa pesanan', 'total pesanan', 'pesanan pending', 'jumlah pesanan',
            'antrean pesanan', 'rekap pesanan', 'pesanan katalog'
        ])) {
            $pendingCount = Order::where('status', Order::STATUS_PENDING)->count();
            $confirmedCount = Order::where('status', Order::STATUS_CONFIRMED)->count();
            $processingCount = Order::where('status', Order::STATUS_PROCESSING)->count();
            $completedCount = Order::where('status', Order::STATUS_COMPLETED)->count();
            $cancelledCount = Order::where('status', Order::STATUS_CANCELLED)->count();
            $totalCompletedRevenue = (float) Order::where('status', Order::STATUS_COMPLETED)->sum('total_amount');
            $formattedRevenue = number_format($totalCompletedRevenue, 0, ',', '.');

            $summaries[] = "Pesanan Katalog: Pending: {$pendingCount} pesanan; Confirmed: {$confirmedCount} pesanan; Processing: {$processingCount} pesanan; Completed: {$completedCount} pesanan (Omzet Selesai: Rp {$formattedRevenue}); Cancelled: {$cancelledCount} pesanan.";
            $intents[] = 'orders';
        }

        // 2. Intent: Metrik stok produk olahan & etalase katalog
        if ($this->hasAnyPhrase($message, [
            'berapa stok', 'total stok', 'sisa stok', 'stok saat ini', 'stok produk olahan',
            'cek stok', 'produk habis', 'out of stock', 'stok katalog'
        ])) {
            $activeCount = ProcessedProduct::where('status', 'active')->count();
            $activeCatalogStock = (int) ProcessedProduct::where('status', 'active')->sum('stock');
            $totalPhysicalStock = (int) ProcessedProduct::sum('stock');
            $outOfStockCount = ProcessedProduct::where('status', 'out_of_stock')->count();

            $summaries[] = "Stok Katalog Olahan: Produk Aktif di Katalog: {$activeCount} item (Stok Aktif Katalog: {$activeCatalogStock} unit); Total Fisik Gudang (Termasuk Nonaktif): {$totalPhysicalStock} unit; Produk Habis (Out of Stock): {$outOfStockCount} item.";
            $intents[] = 'stock';
        }

        // 3. Intent: Metrik komisi platform BUMDes
        if ($this->hasAnyPhrase($message, [
            'berapa komisi', 'total komisi', 'akumulasi komisi', 'jumlah pades', 'pendapatan platform'
        ])) {
            $rate = Commission::DEFAULT_RATE ?? 3.00;
            $commissionQuery = Commission::whereIn('status', ['calculated', 'settled']);
            $totalCommission = (float) $commissionQuery->sum('commission_amount');
            $totalTransactions = $commissionQuery->count();
            $formattedCommission = number_format($totalCommission, 0, ',', '.');

            $summaries[] = "Komisi Platform: Tarif Baku: {$rate}%; Akumulasi Komisi Sah (Calculated/Settled): Rp {$formattedCommission} (dari {$totalTransactions} transaksi).";
            $intents[] = 'commission';
        }

        // 4. Intent: Metrik jumlah Poktan & mitra desa
        if ($this->hasAnyPhrase($message, [
            'berapa jumlah petani', 'total kelompok tani', 'berapa poktan', 'total mitra desa'
        ])) {
            $totalPoktan = FarmerGroup::count();
            $totalFarmers = User::whereIn('role', ['user', 'farmer'])->count();

            $summaries[] = "Mitra Desa: Total Kelompok Tani (Poktan): {$totalPoktan} Poktan; Total Petani Terdaftar: {$totalFarmers} petani.";
            $intents[] = 'farmer_groups';
        }

        // 5. Intent: Harga acuan pasar komoditas desa
        if ($this->hasAnyPhrase($message, [
            'harga pasar', 'harga acuan', 'analisis harga', 'harga komoditas', 'tren harga', 'pasar komoditas', 'harga saat ini', 'harga'
        ])) {
            $commodities = FarmerCommodity::where('status', 'active')->get();
            $priceItems = [];
            foreach ($commodities as $commodity) {
                $latestPrice = MarketPrice::where('commodity_id', $commodity->id)
                    ->whereDate('effective_date', '<=', now()->toDateString())
                    ->orderBy('effective_date', 'desc')
                    ->first();

                if ($latestPrice) {
                    $formattedPrice = number_format((float) $latestPrice->price, 0, ',', '.');
                    $date = $latestPrice->effective_date->format('d/m/Y');
                    $priceItems[] = "{$commodity->name}: Rp {$formattedPrice}/{$latestPrice->unit} (per {$date})";
                }
            }

            if (!empty($priceItems)) {
                $summaries[] = "Harga Acuan Pasar Resmi BUMDes:\n  - " . implode("\n  - ", $priceItems);
            } else {
                $summaries[] = "Harga Acuan Pasar: Belum ada data harga pasar resmi aktif yang tercatat di database.";
            }
            $intents[] = 'market_price';
        }

        if (empty($summaries)) {
            return ['has_data' => false, 'intent' => null, 'summary' => null];
        }

        return [
            'has_data' => true,
            'intent'   => implode(',', $intents),
            'summary'  => "DATA RESMI DATABASE SUMBERTANI:\n• " . implode("\n• ", $summaries),
        ];
    }

    /**
     * Memeriksa apakah salah satu frasa pencocok terdapat dalam pesan dengan batas kata (word boundary).
     */
    protected function hasAnyPhrase(string $message, array $phrases): bool
    {
        foreach ($phrases as $phrase) {
            $cleanPhrase = trim(strtolower($phrase));
            $pattern = '/\b' . preg_quote($cleanPhrase, '/') . '\b/i';
            if (preg_match($pattern, $message)) {
                return true;
            }
        }
        return false;
    }

    /**
     * Memeriksa apakah satu kata kunci terdapat dalam teks dengan batas kata.
     */
    protected function matchesWord(string $word, string $text): bool
    {
        $cleanWord = trim(strtolower($word));
        $pattern = '/\b' . preg_quote($cleanWord, '/') . '\b/i';
        return (bool) preg_match($pattern, $text);
    }
}
