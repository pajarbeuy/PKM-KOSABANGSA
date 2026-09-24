import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';
import '../models/stock.dart';
import 'package:intl/intl.dart';
import '../widgets/app_theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_shell.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  late ApiService _apiService;
  StockData? _stockData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _loadStock();
  }

  Future<void> _loadStock() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stock = await _apiService.getStock();
      if (mounted) {
        setState(() {
          _stockData = stock;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: 'stock',
      title: 'Data Stok',
      subtitle: 'Pantau stok dan riwayat transaksi',
      onRefresh: _loadStock,
      headerActions: [
        ElevatedButton.icon(
          onPressed: () => _showAddStockDialog(context),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Tambah Stok', style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.green700,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      ],
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.green700,
        onPressed: () => _showAddStockDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.green700,
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadStock,
              color: AppTheme.green700,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 800) {
                    return _buildDesktopLayout();
                  }
                  return _buildMobileLayout();
                },
              ),
            ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_stockData != null) ...[
            _buildSummaryCards(),
            const SizedBox(height: 24),
            _buildTransactionsList(),
          ] else ...[
            _buildEmptyState(),
          ],
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_stockData != null) ...[
            _buildDesktopSummaryCards(),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Riwayat Transaksi Stok',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  if (_stockData!.transactions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'Belum ada transaksi',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: MediaQuery.of(context).size.width - 48,
                        ),
                        child: DataTable(
                          headingRowColor:
                              WidgetStateProperty.resolveWith<Color>((
                                Set<WidgetState> states,
                              ) {
                                return const Color(0xFFF9FAFB);
                              }),
                          dataRowMaxHeight: 65,
                          columns: const [
                            DataColumn(
                              label: Text(
                                'Tanggal Transaksi',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Jenis Transaksi',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Jumlah',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Keterangan',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                          rows: _stockData!.transactions.map((transaction) {
                            final isIncoming = transaction.type == 'in';
                            final color = isIncoming
                                ? const Color(0xFF166534)
                                : const Color(0xFF991B1B);
                            final bgColor = isIncoming
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFFEE2E2);
                            final label = isIncoming
                                ? 'Stok Masuk'
                                : 'Stok Keluar';

                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    DateFormat('dd MMM yyyy, HH:mm').format(
                                      _safeParseDate(
                                        transaction.transactionDate,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: bgColor,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isIncoming
                                              ? Icons.arrow_downward
                                              : Icons.arrow_upward,
                                          size: 14,
                                          color: color,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          label,
                                          style: TextStyle(
                                            color: color,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '${transaction.quantity} ${transaction.unit}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(transaction.notes?.isNotEmpty == true ? transaction.notes! : '-'),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ] else ...[
            _buildEmptyState(),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Tidak ada data stok',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: [
        _buildSummaryCard(
          'Masuk',
          '${_stockData!.totalIncoming} kg',
          Icons.arrow_downward,
          Colors.green,
        ),
        _buildSummaryCard(
          'Keluar',
          '${_stockData!.totalOutgoing} kg',
          Icons.arrow_upward,
          Colors.red,
        ),
        _buildSummaryCard(
          'Saat Ini',
          '${_stockData!.currentStock} kg',
          Icons.inventory,
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildDesktopSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildDesktopSummaryCard(
            'Total Masuk',
            '${_stockData!.totalIncoming} kg',
            Icons.arrow_downward,
            const Color(0xFF1A7A4A),
            const Color(0xFFE8F5E9),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDesktopSummaryCard(
            'Total Keluar',
            '${_stockData!.totalOutgoing} kg',
            Icons.arrow_upward,
            const Color(0xFFE74C3C),
            const Color(0xFFFFEBEE),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDesktopSummaryCard(
            'Stok Saat Ini',
            '${_stockData!.currentStock} kg',
            Icons.inventory_2,
            const Color(0xFF3B82F6),
            const Color(0xFFEFF6FF),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopSummaryCard(
    String label,
    String value,
    IconData icon,
    Color iconColor,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 32),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    if (_stockData!.transactions.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Riwayat Transaksi',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _stockData!.transactions.length,
            separatorBuilder: (context, index) =>
                Divider(color: Colors.grey.shade200, height: 1),
            itemBuilder: (context, index) =>
                _buildTransactionTile(_stockData!.transactions[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionTile(StockTransaction transaction) {
    final isIncoming = transaction.type == 'in';
    final color = isIncoming ? Colors.green : Colors.red;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isIncoming ? Icons.arrow_downward : Icons.arrow_upward,
          color: color,
        ),
      ),
      title: Text(
        isIncoming ? 'Stok Masuk' : 'Stok Keluar',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat(
              'dd MMM yyyy, HH:mm',
            ).format(_safeParseDate(transaction.transactionDate)),
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          if (transaction.notes != null && transaction.notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Keterangan: ${transaction.notes!}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ],
      ),
      trailing: Text(
        '${transaction.quantity} ${transaction.unit}',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  DateTime _safeParseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return DateTime.now();
    return DateTime.tryParse(dateStr) ?? DateTime.now();
  }

  void _showAddStockDialog(BuildContext context) {
    String type = 'in';
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Sesuaikan Stok', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setModalState(() => type = 'in'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: type == 'in' ? AppTheme.green100 : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: type == 'in' ? AppTheme.green700 : Colors.transparent),
                              ),
                              child: Center(
                                child: Text('Stok Masuk', style: TextStyle(color: type == 'in' ? AppTheme.green700 : Colors.grey.shade700, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => setModalState(() => type = 'out'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: type == 'out' ? AppTheme.red100 : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: type == 'out' ? AppTheme.red600 : Colors.transparent),
                              ),
                              child: Center(
                                child: Text('Stok Keluar', style: TextStyle(color: type == 'out' ? AppTheme.red600 : Colors.grey.shade700, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Jumlah (Kg)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(
                        labelText: 'Keterangan (opsional)',
                        hintText: 'Misal: Hasil panen busuk / susut',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: isSaving ? null : () async {
                        final amountText = amountController.text;
                        if (amountText.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jumlah harus diisi')));
                          return;
                        }
                        final amount = int.tryParse(amountText);
                        if (amount == null || amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jumlah tidak valid')));
                          return;
                        }

                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);
                        setModalState(() => isSaving = true);
                        final result = await _apiService.addStockTransaction(
                          type: type,
                          amount: amount,
                          notes: notesController.text.isEmpty ? null : notesController.text,
                        );

                        if (mounted) {
                          if (result['success']) {
                            navigator.pop();
                            _loadStock();
                            messenger.showSnackBar(SnackBar(content: Text(result['message'] ?? 'Transaksi stok berhasil'), backgroundColor: Colors.green));
                          } else {
                            setModalState(() => isSaving = false);
                            messenger.showSnackBar(SnackBar(content: Text(result['message'] ?? 'Gagal menambah transaksi'), backgroundColor: Colors.red));
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.green700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Simpan Data Stok', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
