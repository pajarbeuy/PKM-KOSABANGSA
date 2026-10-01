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
  DateTime? _selectedDate;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalItems = 0;
  final int _perPage = 10;

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
        page: _currentPage,
        perPage: _perPage,
      );

      if (mounted) {
        setState(() {
          _summary = result['summary'] as CommissionSummary?;
          _commissions = result['commissions'] as List<Commission>;
          _totalItems = result['total'] as int? ?? _commissions.length;
          _lastPage = result['last_page'] as int? ?? 1;
          _currentPage = result['current_page'] as int? ?? _currentPage;
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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
      helpText: 'Pilih Tanggal Transaksi Komisi',
      cancelText: 'Batal',
      confirmText: 'Terapkan',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.green700,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _startDate = DateFormat('yyyy-MM-dd').format(picked);
        _endDate = DateFormat('yyyy-MM-dd').format(picked);
        _currentPage = 1;
      });
      _loadData();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDate = null;
      _startDate = null;
      _endDate = null;
      _currentPage = 1;
    });
    _loadData();
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
            if (isSuperAdmin)
              _buildSearchBar()
            else
              _buildDateSelector(),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator(color: AppTheme.green700)),
              )
            else if (_filteredCommissions.isEmpty)
              _buildEmptyState(isSuperAdmin)
            else ...[
              _buildCommissionList(_filteredCommissions, isSuperAdmin),
              _buildPaginationControl(),
            ],
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

  Widget _buildDateSelector() {
    final hasFilter = _selectedDate != null;
    final dateDisplay = hasFilter
        ? DateFormat('d MMMM yyyy', 'id').format(_selectedDate!)
        : 'Semua Tanggal Transaksi';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasFilter ? AppTheme.green700 : AppTheme.cardBorder,
          width: hasFilter ? 1.5 : 1.0,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: hasFilter ? AppTheme.green100 : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              size: 20,
              color: hasFilter ? AppTheme.green700 : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Cek Transaksi Tanggal',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  dateDisplay,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: hasFilter ? AppTheme.green800 : AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (hasFilter) ...[
            TextButton.icon(
              onPressed: _clearDateFilter,
              icon: const Icon(Icons.close_rounded, size: 16, color: AppTheme.red600),
              label: const Text('Reset', style: TextStyle(fontSize: 12, color: AppTheme.red600)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 8),
          ],
          ElevatedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.edit_calendar_rounded, size: 16),
            label: Text(hasFilter ? 'Ubah' : 'Pilih Tanggal', style: const TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.green700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isSuperAdmin) {
    final hasDateFilter = !isSuperAdmin && _selectedDate != null;

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
          Text(
            hasDateFilter
                ? 'Tidak ada transaksi pada tanggal ini'
                : 'Belum ada transaksi komisi',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            hasDateFilter
                ? 'Tidak ditemukan catatan transaksi komisi pada ${DateFormat('d MMMM yyyy', 'id').format(_selectedDate!)}.'
                : (isSuperAdmin
                    ? 'Komisi platform 10% akan otomatis dicatat setiap kali pesanan diselesaikan atau penjualan dicatat.'
                    : 'Potongan komisi platform 10% akan otomatis dicatat saat produk olahan Anda terjual.'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          if (hasDateFilter) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _clearDateFilter,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Tampilkan Semua Tanggal'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.green700,
                side: const BorderSide(color: AppTheme.green700),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommissionList(List<Commission> items, bool isSuperAdmin) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildCommissionCard(item, isSuperAdmin);
      },
    );
  }

  Widget _buildCommissionCard(Commission item, bool isSuperAdmin) {
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
                      isSuperAdmin
                          ? 'Petani: ${item.farmerName ?? 'Mitra Tani #${item.userId}'}${item.productName != null ? ' • ${item.productName}' : ''}'
                          : (item.productName != null ? 'Produk: ${item.productName}' : 'Penjualan Produk Mitra Tani'),
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
                label: isSuperAdmin ? 'Penerimaan Petani (90%)' : 'Penerimaan Bersih Anda (90%)',
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

  Widget _buildPaginationControl() {
    if (_lastPage <= 1 && _totalItems <= _perPage) {
      return const SizedBox.shrink();
    }

    final fromIndex = _commissions.isEmpty ? 0 : ((_currentPage - 1) * _perPage) + 1;
    final toIndex = ((_currentPage - 1) * _perPage) + _commissions.length;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Menampilkan $fromIndex–$toIndex dari $_totalItems transaksi',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _currentPage > 1 && !_isLoading
                    ? () {
                        setState(() => _currentPage--);
                        _loadData();
                      }
                    : null,
                icon: const Icon(Icons.chevron_left_rounded, size: 18),
                label: const Text('Sebelumnya', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  side: BorderSide(
                    color: _currentPage > 1 ? AppTheme.green700 : Colors.grey.shade300,
                  ),
                  foregroundColor: AppTheme.green700,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.green100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Hal. $_currentPage / $_lastPage',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.green800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _currentPage < _lastPage && !_isLoading
                    ? () {
                        setState(() => _currentPage++);
                        _loadData();
                      }
                    : null,
                icon: const Icon(Icons.chevron_right_rounded, size: 18),
                label: const Text('Berikutnya', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  side: BorderSide(
                    color: _currentPage < _lastPage ? AppTheme.green700 : Colors.grey.shade300,
                  ),
                  foregroundColor: AppTheme.green700,
                ),
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
