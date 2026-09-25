import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/processed_product.dart';
import '../services/api_service.dart';
import 'app_theme.dart';

double _toDouble(dynamic v, [double defaultValue = 0.0]) {
  if (v == null) return defaultValue;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? defaultValue;
  return defaultValue;
}

class ProcessedEconomicDialog extends StatefulWidget {
  final ProcessedProduct product;

  const ProcessedEconomicDialog({super.key, required this.product});

  @override
  State<ProcessedEconomicDialog> createState() => _ProcessedEconomicDialogState();
}

class _ProcessedEconomicDialogState extends State<ProcessedEconomicDialog> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _summary;
  String? _errorMessage;

  final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

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
      final summary = await _apiService.getProcessedProductEconomicSummary(widget.product.id);
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
          maxWidth: 650,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(
                color: AppTheme.green700,
              ),
              child: Row(
                children: [
                  const Icon(Icons.analytics_outlined, color: Colors.white, size: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Analisis Modal & Laba Olahan',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.product.name,
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
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

            // ── Body ────────────────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.green700))
                  : _errorMessage != null
                      ? Center(child: Text('Error: $_errorMessage'))
                      : _summary == null
                          ? const Center(child: Text('Data tidak ditemukan.'))
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ── Summary KPI Banner ────────────────────
                                  _buildProfitBanner(_summary!),
                                  const SizedBox(height: 20),

                                  // ── Metrics Grid ──────────────────────────
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildMetricCard(
                                          title: 'Bahan Baku Kebun',
                                          value: '${_summary!['raw_material_weight_kg'] ?? 0} kg',
                                          subtitle: 'Modal Tunai: Rp 0 (Bebas dobel)',
                                          icon: Icons.grass_outlined,
                                          color: const Color(0xFF166534),
                                          bgColor: const Color(0xFFDCFCE7),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildMetricCard(
                                          title: 'Modal Bahan Penolong',
                                          value: _currencyFormat.format(_toDouble(_summary!['total_processing_cost'])),
                                          subtitle: 'Tepung, minyak, packaging',
                                          icon: Icons.inventory_2_outlined,
                                          color: const Color(0xFF9A3412),
                                          bgColor: const Color(0xFFFFEDD5),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildMetricCard(
                                          title: 'Penjualan Terwujud',
                                          value: _currencyFormat.format(_toDouble(_summary!['realized_revenue'])),
                                          subtitle: '${_summary!['units_sold'] ?? 0} ${widget.product.unit} terjual',
                                          icon: Icons.shopping_bag_outlined,
                                          color: const Color(0xFF1E40AF),
                                          bgColor: const Color(0xFFDBEAFE),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildMetricCard(
                                          title: 'HPP / Modal per Unit',
                                          value: _currencyFormat.format(_toDouble(_summary!['cost_per_unit'])),
                                          subtitle: 'Harga Jual: ${_currencyFormat.format(widget.product.price)}',
                                          icon: Icons.price_check_outlined,
                                          color: const Color(0xFF5B21B6),
                                          bgColor: const Color(0xFFEDE9FE),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),

                                  // ── Rincian Biaya Bahan Penolong ──────────
                                  const Text(
                                    'Rincian Biaya Bahan Penolong (Modal Olahan)',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                                  ),
                                  const SizedBox(height: 8),

                                  Builder(
                                    builder: (context) {
                                      final costs = (_summary!['costs'] as List?) ?? [];
                                      if (costs.isEmpty) {
                                        return Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade50,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.grey.shade200),
                                          ),
                                          child: const Center(
                                            child: Text('Belum ada rincian bahan penolong tambahan yang dicatat.'),
                                          ),
                                        );
                                      }

                                      return Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey.shade200),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: Column(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                              color: Colors.grey.shade100,
                                              child: const Row(
                                                children: [
                                                  Expanded(flex: 3, child: Text('Item / Bahan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                                  Expanded(flex: 2, child: Text('Jumlah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                                  Expanded(flex: 2, child: Text('Harga/Unit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                                  Expanded(flex: 2, child: Text('Total', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                                ],
                                              ),
                                            ),
                                            const Divider(height: 1),
                                            ...costs.map((c) {
                                              final name = c['item_name'] ?? c['category'] ?? 'Bahan';
                                              final qty = c['quantity'] != null ? '${c['quantity']} ${c['unit'] ?? ''}' : '–';
                                              final price = c['price_per_unit'] != null ? _currencyFormat.format(_toDouble(c['price_per_unit'])) : '–';
                                              final amount = _toDouble(c['amount']);

                                              return Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      flex: 3,
                                                      child: Text(
                                                        name,
                                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                                      ),
                                                    ),
                                                    Expanded(flex: 2, child: Text(qty, style: const TextStyle(fontSize: 12))),
                                                    Expanded(flex: 2, child: Text(price, style: const TextStyle(fontSize: 12))),
                                                    Expanded(
                                                      flex: 2,
                                                      child: Text(
                                                        _currencyFormat.format(amount),
                                                        textAlign: TextAlign.right,
                                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }),
                                          ],
                                        ),
                                      );
                                    },
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

  Widget _buildProfitBanner(Map<String, dynamic> s) {
    final profit = _toDouble(s['realized_profit_loss']);
    final isProfit = profit >= 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isProfit ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isProfit ? const Color(0xFF86EFAC) : const Color(0xFFFECACA),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isProfit ? 'LABA BERSIH OLAHAN' : 'DEFISIT OLAHAN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                  color: isProfit ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _currencyFormat.format(profit),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: isProfit ? const Color(0xFF166534) : const Color(0xFF991B1B),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isProfit ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isProfit ? 'PROFITABEL' : 'BELUM UNTUNG',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isProfit ? const Color(0xFF166534) : const Color(0xFF991B1B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
