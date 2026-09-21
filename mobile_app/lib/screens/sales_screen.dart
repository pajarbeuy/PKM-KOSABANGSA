import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../models/sale.dart';
import 'package:intl/intl.dart';
import '../widgets/app_theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_shell.dart';
import 'add_edit_sale_screen.dart';

class SalesScreen extends StatefulWidget {
  final bool isEmbedded;
  const SalesScreen({super.key, this.isEmbedded = false});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  late ApiService _apiService;
  List<Sale> _sales = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _loadSales();
  }

  Future<void> _loadSales() async {
    setState(() => _isLoading = true);

    try {
      final sales = await _apiService.getSales();
      if (mounted) {
        setState(() {
          _sales = sales;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteSale(Sale sale) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Penjualan'),
        content: Text('Yakin hapus penjualan ke "${sale.buyerName}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final result = await _apiService.deleteSale(sale.id);
      if (result['success'] == true) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Penjualan berhasil dihapus'),
            backgroundColor: AppTheme.green700,
          ),
        );
        _loadSales();
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal menghapus'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showSaleForm({Sale? sale}) async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditSaleScreen(
        sale: sale,
        onSaved: _loadSales,
      ),
    );

    if (added == true) {
      _loadSales();
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _isLoading
        ? const Center(child: CircularProgressIndicator(color: AppTheme.green700))
        : RefreshIndicator(
            onRefresh: _loadSales,
            color: AppTheme.green700,
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 800) {
                  return _buildDesktopLayout();
                }
                return _buildMobileLayout();
              },
            ),
          );

    if (widget.isEmbedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Transaksi Penjualan Terpusat',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.dark900),
                ),
                ElevatedButton.icon(
                  onPressed: _showSaleForm,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Catat Penjualan', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.green700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: content),
        ],
      );
    }

    return AppShell(
      currentRoute: 'sales',
      title: 'Penjualan',
      subtitle: 'Kelola transaksi penjualan komoditas',
      onRefresh: _loadSales,
      headerActions: [
        ElevatedButton.icon(
          onPressed: _showSaleForm,
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Tambah Penjualan', style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.green700,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      ],
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
      floatingActionButton: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            backgroundColor: AppTheme.green700,
            foregroundColor: Colors.white,
            onPressed: _showSaleForm,
            icon: const Icon(Icons.add),
            label: const Text('Tambah Penjualan',
                style: TextStyle(fontWeight: FontWeight.bold)),
          );
        },
      ),
      child: content,
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Tidak ada data penjualan',
              style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 18,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('Mulai dengan menambahkan transaksi pertama.',
              style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  // ── Mobile Layout ──────────────────────────────────────────────────────────
  Widget _buildMobileLayout() {
    if (_sales.isEmpty) return _buildEmptyState();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sales.length,
      itemBuilder: (context, index) {
        final sale = _sales[index];
        final isLunas = sale.status == 'completed';

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppTheme.cardBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        DateFormat('d MMM yyyy', 'id').format(_safeParseDate(sale.saleDate)),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppTheme.textPrimary),
                      ),
                    ),
                    _StatusBadge(isLunas: isLunas),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  sale.buyerName,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.scale_outlined, size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text('${sale.quantity} kg', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('Total:', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    const SizedBox(width: 6),
                    Text(
                      _formatCurrency(sale.totalPrice),
                      style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.green700,
                          fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _ActionBtn(
                      icon: Icons.edit_outlined,
                      color: AppTheme.blue600,
                      bgColor: AppTheme.blue100,
                      tooltip: 'Edit',
                      onTap: () => _showSaleForm(sale: sale),
                    ),
                    const SizedBox(width: 8),
                    _ActionBtn(
                      icon: Icons.delete_outline,
                      color: AppTheme.red600,
                      bgColor: AppTheme.red100,
                      tooltip: 'Hapus',
                      onTap: () => _deleteSale(sale),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Desktop Layout ─────────────────────────────────────────────────────────
  Widget _buildDesktopLayout() {
    int totalPendapatan = 0;
    int sudahLunas = 0;
    int piutang = 0;

    for (var sale in _sales) {
      totalPendapatan += sale.totalPrice;
      if (sale.status == 'completed') {
        sudahLunas += sale.totalPrice;
      } else {
        piutang += sale.totalPrice;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Stat Cards
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.attach_money,
                  label: 'Total Pendapatan',
                  value: _formatJt(totalPendapatan),
                  iconColor: AppTheme.green700,
                  iconBg: AppTheme.green100,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  icon: Icons.trending_up,
                  label: 'Sudah Lunas',
                  value: _formatJt(sudahLunas),
                  iconColor: AppTheme.green700,
                  iconBg: AppTheme.green100,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Piutang',
                  value: _formatJt(piutang),
                  iconColor: Colors.orange.shade700,
                  iconBg: Colors.orange.shade100,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Table
          if (_sales.isEmpty)
            Container(
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
              ),
              child: _buildEmptyState(),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Table Header
                  Container(
                    color: const Color(0xFFF9FAFB),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    child: const Row(
                      children: [
                        _ColHeader(text: 'TANGGAL', flex: 2),
                        _ColHeader(text: 'PEMBELI', flex: 4),
                        _ColHeader(text: 'JUMLAH', flex: 2),
                        _ColHeader(text: 'HARGA/KG', flex: 2),
                        _ColHeader(text: 'TOTAL', flex: 3),
                        _ColHeader(text: 'STATUS', flex: 2),
                        _ColHeader(text: 'AKSI', flex: 2),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  // Table Rows
                  ...List.generate(_sales.length, (index) {
                    final sale = _sales[index];
                    final isLast = index == _sales.length - 1;
                    final isLunas = sale.status == 'completed';

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          child: Row(
                            children: [
                              // TANGGAL
                              Expanded(
                                flex: 2,
                                child: Text(
                                  DateFormat('d MMM yyyy').format(
                                      _safeParseDate(sale.saleDate)),
                                  style: const TextStyle(
                                      fontSize: 14, color: AppTheme.textPrimary),
                                ),
                              ),
                              // PEMBELI
                              Expanded(
                                flex: 4,
                                child: Text(
                                  sale.buyerName,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary),
                                ),
                              ),
                              // JUMLAH
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${sale.quantity} kg',
                                  style: const TextStyle(
                                      fontSize: 14, color: AppTheme.textPrimary),
                                ),
                              ),
                              // HARGA/KG
                              Expanded(
                                flex: 2,
                                child: Text(
                                  _formatCurrency(sale.pricePerUnit),
                                  style: const TextStyle(
                                      fontSize: 14, color: AppTheme.textSecondary),
                                ),
                              ),
                              // TOTAL
                              Expanded(
                                flex: 3,
                                child: Text(
                                  _formatCurrency(sale.totalPrice),
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.green700),
                                ),
                              ),
                              // STATUS
                              Expanded(
                                flex: 2,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: _StatusBadge(isLunas: isLunas),
                                ),
                              ),
                              // AKSI
                              Expanded(
                                flex: 2,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _ActionBtn(
                                      icon: Icons.edit_outlined,
                                      color: AppTheme.blue600,
                                      bgColor: AppTheme.blue100,
                                      tooltip: 'Edit',
                                      onTap: () => _showSaleForm(sale: sale),
                                    ),
                                    const SizedBox(width: 8),
                                    _ActionBtn(
                                      icon: Icons.delete_outline,
                                      color: AppTheme.red600,
                                      bgColor: AppTheme.red100,
                                      tooltip: 'Hapus',
                                      onTap: () => _deleteSale(sale),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isLast)
                          const Divider(height: 1, color: Color(0xFFF3F4F6)),
                      ],
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Formatters & Helpers ───────────────────────────────────────────────────

  String _formatCurrency(int value) {
    return 'Rp ${value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';
  }

  String _formatJt(int value) {
    if (value >= 1000000) {
      final double result = value / 1000000;
      // Remove trailing zero if it's a whole number (e.g., 4.0 jt -> 4 jt)
      return 'Rp ${result.toStringAsFixed(result.truncateToDouble() == result ? 0 : 1)} jt';
    }
    return _formatCurrency(value);
  }

  DateTime _safeParseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return DateTime.now();
    return DateTime.tryParse(dateStr) ?? DateTime.now();
  }
}

// ── Shared Widgets ───────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color iconBg;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 16),
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}

class _ColHeader extends StatelessWidget {
  final String text;
  final int flex;

  const _ColHeader({required this.text, required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
              color: bgColor, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isLunas;
  const _StatusBadge({required this.isLunas});

  @override
  Widget build(BuildContext context) {
    final bgColor = isLunas ? const Color(0xFFDCFCE7) : const Color(0xFFFFEDD5);
    final txtColor = isLunas ? const Color(0xFF166534) : const Color(0xFF9A3412);
    final text = isLunas ? 'Lunas' : 'Hutang';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: txtColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
