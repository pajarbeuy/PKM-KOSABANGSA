import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../widgets/app_theme.dart';

double _toDouble(dynamic v, [double defaultValue = 0.0]) {
  if (v == null) return defaultValue;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? defaultValue;
  return defaultValue;
}

int _toInt(dynamic v, [int defaultValue = 0]) {
  if (v == null) return defaultValue;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? defaultValue;
  return defaultValue;
}

class SuperAdminProfitLossScreen extends StatefulWidget {
  final bool isEmbedded;
  const SuperAdminProfitLossScreen({super.key, this.isEmbedded = false});

  @override
  State<SuperAdminProfitLossScreen> createState() => _SuperAdminProfitLossScreenState();
}

class _SuperAdminProfitLossScreenState extends State<SuperAdminProfitLossScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _aggregateData;

  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getFarmerProfitLossAggregate();
      setState(() {
        _aggregateData = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data agregat laba rugi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalRevenue = _toDouble(_aggregateData?['total_farmer_revenue']);
    final totalCost = _toDouble(_aggregateData?['total_farmer_cost']);
    final totalProfitLoss = _toDouble(_aggregateData?['total_farmer_profit_loss']);
    final farmerCount = _toInt(_aggregateData?['farmer_count']);
    final farmers = (_aggregateData?['farmers'] as List?) ?? [];

    final isNetProfit = totalProfitLoss >= 0;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.green700,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.green700.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.green700.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.analytics_outlined, color: AppTheme.green700, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Agregat Laba / Rugi Seluruh Mitra Tani',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.dark900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Formula Baku: Total Pendapatan Petani - Total Biaya Produksi. Memantau performa finansial gabungan seluruh mitra tani binaan.',
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // KPI Cards Row
            Row(
              children: [
                _buildKpiCard('Total Pendapatan', _currencyFormat.format(totalRevenue), Icons.trending_up, Colors.green),
                const SizedBox(width: 12),
                _buildKpiCard('Total Biaya', _currencyFormat.format(totalCost), Icons.trending_down, Colors.orange),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildKpiCard(
                  'Agregat Laba / Rugi',
                  _currencyFormat.format(totalProfitLoss),
                  isNetProfit ? Icons.check_circle_outline : Icons.cancel_outlined,
                  isNetProfit ? AppTheme.green700 : Colors.red,
                  highlight: true,
                ),
                const SizedBox(width: 12),
                _buildKpiCard('Mitra Tani', '$farmerCount Petani', Icons.people_outline, Colors.blue),
              ],
            ),
            const SizedBox(height: 24),

            // Farmers breakdown table
            const Text(
              'Rincian Performa Finansial Petani',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.dark900),
            ),
            const SizedBox(height: 12),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: AppTheme.green700),
                ),
              )
            else if (farmers.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(Icons.folder_open_outlined, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    const Text('Belum ada data petani terdaftar.', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: farmers.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  final f = farmers[i] as Map<String, dynamic>;
                  final rev = _toDouble(f['revenue']);
                  final cost = _toDouble(f['cost']);
                  final pl = _toDouble(f['profit_loss']);
                  final isProfit = pl >= 0;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              f['farmer_name'] ?? 'Petani',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: isProfit ? Colors.green[50] : Colors.red[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isProfit ? 'Untung' : 'Rugi',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isProfit ? Colors.green[800] : Colors.red[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (f['farm_name'] != null && f['farm_name'].toString().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(f['farm_name'], style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Pendapatan', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                const SizedBox(height: 2),
                                Text(_currencyFormat.format(rev), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.green)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Biaya Produksi', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                const SizedBox(height: 2),
                                Text(_currencyFormat.format(cost), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.orange)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Net Laba/Rugi', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                const SizedBox(height: 2),
                                Text(
                                  _currencyFormat.format(pl),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isProfit ? AppTheme.green700 : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color, {bool highlight = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: highlight ? color.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: highlight ? color.withValues(alpha: 0.3) : Colors.grey[200]!),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                Icon(icon, color: color, size: 18),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: highlight ? color : AppTheme.dark900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
