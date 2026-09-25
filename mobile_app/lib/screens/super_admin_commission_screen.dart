import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/commission.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/app_shell.dart';
import '../widgets/app_theme.dart';

class SuperAdminCommissionScreen extends StatefulWidget {
  final bool isEmbedded;
  const SuperAdminCommissionScreen({super.key, this.isEmbedded = false});

  @override
  State<SuperAdminCommissionScreen> createState() => _SuperAdminCommissionScreenState();
}

class _SuperAdminCommissionScreenState extends State<SuperAdminCommissionScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Commission> _commissions = [];
  CommissionSummary? _summary;
  String? _startDate;
  String? _endDate;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

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

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final result = await _apiService.getCommissions(
        startDate: _startDate,
        endDate: _endDate,
      );

      if (mounted) {
        setState(() {
          _summary = result['summary'] as CommissionSummary?;
          _commissions = result['commissions'] as List<Commission>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat data komisi: $e'),
          backgroundColor: AppTheme.red600,
        ),
      );
    }
  }

  List<Commission> get _filteredCommissions {
    if (_searchQuery.isEmpty) return _commissions;
    final q = _searchQuery.toLowerCase();
    return _commissions.where((c) {
      return (c.farmerName?.toLowerCase().contains(q) ?? false) ||
          (c.productName?.toLowerCase().contains(q) ?? false) ||
          (c.orderCode?.toLowerCase().contains(q) ?? false) ||
          c.saleId.toString().contains(q);
    }).toList();
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('d MMM yyyy, HH:mm', 'id').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isSuperAdmin = user?.role == 'super_admin';

    final content = RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.green700,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isSuperAdmin),
            const SizedBox(height: 20),
            if (_summary != null) _buildSummaryKpis(_summary!, isSuperAdmin),
            const SizedBox(height: 20),
            _buildSearchBar(),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator(color: AppTheme.green700)),
              )
            else if (_filteredCommissions.isEmpty)
              _buildEmptyState()
            else
              _buildCommissionList(_filteredCommissions),
          ],
        ),
      ),
    );

    if (widget.isEmbedded) {
      return content;
    }

    return AppShell(
      currentRoute: 'commissions',
      title: isSuperAdmin ? 'Komisi Platform (10%)' : 'Komisi Penjualan (10%)',
      subtitle: isSuperAdmin
          ? 'Pantauan pendapatan komisi 10% platform dari setiap transaksi penjualan'
          : 'Rincian potongan komisi platform 10% atas transaksi penjualan produk Anda',
      child: content,
    );
  }

  Widget _buildHeader(bool isSuperAdmin) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF115E59), Color(0xFF134E4A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSuperAdmin ? 'Pendapatan Komisi Platform 10%' : 'Bagi Hasil & Komisi Platform',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isSuperAdmin
                          ? 'Perhitungan 10% otomatis di sisi server dari nilai transaksi kotor (Gross)'
                          : 'Potongan 10% platform untuk operasional pemasaran, katalog, dan penanganan order',
                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.85)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_outlined, color: Color(0xFF5EEAD4), size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Aturan Baku Phase 8: Komisi 10% dihitung dari Gross Transaksi. Terisolasi dari biaya produksi petani & immutable.',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryKpis(CommissionSummary summary, bool isSuperAdmin) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 750;

        final cards = [
          _buildKpiCard(
            label: isSuperAdmin ? 'Total Transaksi' : 'Total Penjualan Anda',
            value: '${summary.totalTransactions} Transaksi',
            icon: Icons.receipt_long_outlined,
            color: const Color(0xFF2563EB),
            bgColor: const Color(0xFFEFF6FF),
          ),
          _buildKpiCard(
            label: 'Total Transaksi Bruto (Gross)',
            value: _currencyFormat.format(summary.totalGrossAmount),
            icon: Icons.payments_outlined,
            color: const Color(0xFF059669),
            bgColor: const Color(0xFFECFDF5),
          ),
          _buildKpiCard(
            label: isSuperAdmin ? 'Pendapatan Komisi (10%)' : 'Potongan Komisi Platform (10%)',
            value: _currencyFormat.format(summary.totalCommissionAmount),
            icon: Icons.pie_chart_outline,
            color: const Color(0xFFD97706),
            bgColor: const Color(0xFFFFFBEB),
          ),
          _buildKpiCard(
            label: isSuperAdmin ? 'Penerimaan Bersih Petani (90%)' : 'Penerimaan Bersih Anda (90%)',
            value: _currencyFormat.format(summary.totalNetFarmerAmount),
            icon: Icons.agriculture_outlined,
            color: const Color(0xFF7C3AED),
            bgColor: const Color(0xFFF5F3FF),
          ),
        ];

        if (isNarrow) {
          return Column(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                cards[i],
                if (i < cards.length - 1) const SizedBox(height: 10),
              ],
            ],
          );
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 14),
                Expanded(child: cards[1]),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: cards[2]),
                const SizedBox(width: 14),
                Expanded(child: cards[3]),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: TextField(
        controller: _searchCtrl,
        decoration: const InputDecoration(
          hintText: 'Cari nama petani, komoditas, kode order, atau ID transaksi...',
          hintStyle: TextStyle(fontSize: 13, color: AppTheme.textMuted),
          prefixIcon: Icon(Icons.search, size: 20, color: AppTheme.textMuted),
          border: InputBorder.none,
          isDense: true,
        ),
        onChanged: (val) => setState(() => _searchQuery = val.trim()),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Belum ada transaksi komisi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Komisi platform 10% akan otomatis dicatat setiap kali pesanan diselesaikan atau penjualan dicatat.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildCommissionList(List<Commission> items) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildCommissionCard(item);
      },
    );
  }

  Widget _buildCommissionCard(Commission item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFCCFBF1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_outlined, color: Color(0xFF0F766E), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          item.orderCode != null ? 'Pesanan ${item.orderCode}' : 'Penjualan #${item.saleId}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Text(
                            'Komisi ${item.rate.toStringAsFixed(0)}%',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFB45309)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Petani: ${item.farmerName ?? 'Mitra Tani #${item.userId}'}${item.productName != null ? ' • ${item.productName}' : ''}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Text(
                _formatDate(item.createdAt),
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildAmountPill(
                label: 'Nilai Transaksi (Gross)',
                amount: _currencyFormat.format(item.baseAmount),
                color: AppTheme.textPrimary,
              ),
              _buildAmountPill(
                label: 'Komisi Platform (10%)',
                amount: _currencyFormat.format(item.commissionAmount),
                color: const Color(0xFFD97706),
                isBold: true,
              ),
              _buildAmountPill(
                label: 'Penerimaan Petani (90%)',
                amount: _currencyFormat.format(item.netFarmerAmount),
                color: const Color(0xFF059669),
                isBold: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountPill({
    required String label,
    required String amount,
    required Color color,
    bool isBold = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        const SizedBox(height: 2),
        Text(
          amount,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
