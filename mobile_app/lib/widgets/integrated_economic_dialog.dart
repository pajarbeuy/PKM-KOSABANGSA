import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/economic_result.dart';
import '../services/api_service.dart';
import 'app_theme.dart';

class IntegratedEconomicDialog extends StatefulWidget {
  const IntegratedEconomicDialog({super.key});

  @override
  State<IntegratedEconomicDialog> createState() => _IntegratedEconomicDialogState();
}

class _IntegratedEconomicDialogState extends State<IntegratedEconomicDialog> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  IntegratedAgribusinessEconomicSummary? _summary;
  String? _errorMessage;

  final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final _numberFormat = NumberFormat('#,##0.##', 'id_ID');

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final summary = await _apiService.getIntegratedEconomicSummary();
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 720,
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        child: Column(
          children: [
            // ── Modal Header ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1B4D3E), Color(0xFF2D6A4F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Laba / Rugi Agribisnis Terpadu',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Integrasi Hasil Kebun (Hulu) & Produk Olahan (Hilir)',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // ── Content ─────────────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.green700))
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                                const SizedBox(height: 12),
                                Text('Gagal memuat ringkasan: $_errorMessage', textAlign: TextAlign.center),
                                const SizedBox(height: 16),
                                ElevatedButton(onPressed: _loadSummary, child: const Text('Coba Lagi')),
                              ],
                            ),
                          ),
                        )
                      : _summary == null
                          ? const Center(child: Text('Data tidak ditemukan.'))
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ── Grand Total Banner ───────────────────
                                  _buildGrandTotalCard(_summary!),
                                  const SizedBox(height: 24),

                                  // ── Hulu & Hilir Comparison Cards ────────
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final isWide = constraints.maxWidth >= 600;
                                      final hulu = _buildHuluCard(_summary!);
                                      final hilir = _buildHilirCard(_summary!);

                                      if (isWide) {
                                        return Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(child: hulu),
                                            const SizedBox(width: 16),
                                            Expanded(child: hilir),
                                          ],
                                        );
                                      } else {
                                        return Column(
                                          children: [
                                            hulu,
                                            const SizedBox(height: 16),
                                            hilir,
                                          ],
                                        );
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 20),

                                  // ── Zero Double-Counting Guarantee Note ───
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0FDF4),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFBBF7D0)),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.verified_outlined, color: Color(0xFF15803D), size: 20),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Formula Terpadu memastikan biaya budidaya kebun tidak pernah dihitung dua kali saat hasil panen dialihkan ke produk olahan.',
                                            style: TextStyle(fontSize: 12, color: Color(0xFF166534)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrandTotalCard(IntegratedAgribusinessEconomicSummary s) {
    final netProfit = s.totalIntegratedProfitLoss ?? 0.0;
    final isProfitable = netProfit >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isProfitable ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isProfitable ? const Color(0xFF86EFAC) : const Color(0xFFFECACA),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL LABA / RUGI TERPADU',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.bold,
                  color: isProfitable ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isProfitable ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isProfitable ? 'UNTUNG / SURPLUS' : 'DEFISIT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isProfitable ? const Color(0xFF166534) : const Color(0xFF991B1B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _currencyFormat.format(netProfit),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: isProfitable ? const Color(0xFF166534) : const Color(0xFF991B1B),
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Pendapatan Terpadu', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text(
                      _currencyFormat.format(s.totalIntegratedRevenue),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Biaya Gabungan', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text(
                      _currencyFormat.format(s.totalIntegratedCost),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHuluCard(IntegratedAgribusinessEconomicSummary s) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.green100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.grass_outlined, color: AppTheme.green700, size: 20),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('HULU (Kebun)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('Budidaya & Panen Mentah', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMetricRow('Total Panen', '${_numberFormat.format(s.farmHarvestWeightKg)} kg'),
          _buildMetricRow('Dialihkan ke Olahan', '${_numberFormat.format(s.rawMaterialAllocatedKg)} kg'),
          _buildMetricRow('Sisa Jual Mentah', '${_numberFormat.format(s.netHarvestMarketWeightKg)} kg'),
          const Divider(height: 18),
          _buildMetricRow('Modal Tanam Kebun', _currencyFormat.format(s.farmProductionCost)),
          _buildMetricRow('Nilai / Omset Panen', _currencyFormat.format(s.farmRevenue ?? 0)),
          const Divider(height: 18),
          _buildMetricRow(
            'Laba Bersih Hulu',
            _currencyFormat.format(s.farmProfitLoss ?? 0),
            isBold: true,
            color: (s.farmProfitLoss ?? 0) >= 0 ? AppTheme.green800 : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildHilirCard(IntegratedAgribusinessEconomicSummary s) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7), // Amber 100
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.soup_kitchen_outlined, color: Color(0xFFB45309), size: 20),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('HILIR (Olahan)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('Produk Olahan Bernilai Tambah', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMetricRow('Jumlah Produk Olahan', '${s.processedProductCount} varian'),
          _buildMetricRow('Bahan Baku Panen', '${_numberFormat.format(s.rawMaterialAllocatedKg)} kg (Rp 0)'),
          const Divider(height: 18),
          _buildMetricRow('Modal Bahan Penolong', _currencyFormat.format(s.processingProductionCost)),
          _buildMetricRow('Hasil Penjualan Olahan', _currencyFormat.format(s.processedRevenue)),
          const Divider(height: 18),
          _buildMetricRow(
            'Laba Bersih Hilir',
            _currencyFormat.format(s.processedProfitLoss),
            isBold: true,
            color: s.processedProfitLoss >= 0 ? AppTheme.green800 : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: isBold ? AppTheme.textPrimary : Colors.grey.shade600, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 13 : 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
