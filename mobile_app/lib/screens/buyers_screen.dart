import 'package:flutter/material.dart';

import '../models/sale.dart';

import '../services/api_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/app_shell.dart';
import '../utils/thousands_formatter.dart';

class BuyerSummary {
  final String name;
  final String? phone;
  final String? address;
  final int totalQuantity;
  final int totalSpent;
  final int transactionCount;
  final List<Sale> sales;
  final bool hasPiutang;

  BuyerSummary({
    required this.name,
    this.phone,
    this.address,
    required this.totalQuantity,
    required this.totalSpent,
    required this.transactionCount,
    required this.sales,
    required this.hasPiutang,
  });
}

class BuyersScreen extends StatefulWidget {
  const BuyersScreen({super.key});

  @override
  State<BuyersScreen> createState() => _BuyersScreenState();
}

class _BuyersScreenState extends State<BuyersScreen> {
  final ApiService _apiService = ApiService();
  List<BuyerSummary> _buyers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final sales = await _apiService.getSales();
      final Map<String, List<Sale>> grouped = {};

      for (var sale in sales) {
        final key = sale.buyerName.trim().isEmpty ? 'Pembeli Tanpa Nama' : sale.buyerName.trim();
        grouped.putIfAbsent(key, () => []).add(sale);
      }

      final List<BuyerSummary> list = grouped.entries.map((entry) {
        final buyerSales = entry.value;
        int qty = 0;
        int spent = 0;
        String? phone;
        String? address;
        bool piutang = false;

        for (var s in buyerSales) {
          qty += s.quantity;
          spent += s.totalPrice;
          if (s.status != 'completed') {
            piutang = true;
          }
          if ((phone == null || phone.isEmpty) && s.buyerPhone != null && s.buyerPhone!.isNotEmpty) {
            phone = s.buyerPhone;
          }
          if ((address == null || address.isEmpty) && s.buyerAddress != null && s.buyerAddress!.isNotEmpty) {
            address = s.buyerAddress;
          }
        }

        return BuyerSummary(
          name: entry.key,
          phone: phone,
          address: address,
          totalQuantity: qty,
          totalSpent: spent,
          transactionCount: buyerSales.length,
          sales: buyerSales,
          hasPiutang: piutang,
        );
      }).toList();

      list.sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
      // Sort sales in each buyer by date descending
      for (var b in list) {
        b.sales.sort((s1, s2) => s2.saleDate.compareTo(s1.saleDate));
      }

      if (mounted) {
        setState(() {
          _buyers = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data pembeli: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteBuyer(BuyerSummary buyer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Pembeli'),
        content: Text(
          'Hapus pembeli "${buyer.name}" beserta ${buyer.transactionCount} transaksi penjualannya? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    int failed = 0;
    for (final sale in buyer.sales) {
      final result = await _apiService.deleteSale(sale.id);
      if (result['success'] != true) failed++;
    }

    if (!mounted) return;

    if (failed == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pembeli "${buyer.name}" berhasil dihapus.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$failed transaksi gagal dihapus. Coba lagi.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        return AppShell(
          currentRoute: 'buyers',
          title: 'Manajemen Pembeli',
          subtitle: 'Kelola data pembeli dan riwayat transaksi',
          onRefresh: _loadData,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.green700))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: AppTheme.green700,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryCards(isDesktop),
                        const SizedBox(height: 24),
                        _buyers.isEmpty
                            ? _buildEmptyState()
                            : _buildBuyersGrid(isDesktop),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildSummaryCards(bool isDesktop) {
    final totalPembeli = _buyers.length;
    final pembeliAktif = _buyers.where((b) => b.transactionCount > 0).length;
    final adaPiutang = _buyers.where((b) => b.hasPiutang).length;

    final items = [
      _summaryTile('Total Pembeli', '$totalPembeli', Icons.people_outline, AppTheme.green100, AppTheme.green700),
      _summaryTile('Pembeli Aktif', '$pembeliAktif', Icons.person_add_alt_1_outlined, AppTheme.green100, AppTheme.green700),
      _summaryTile('Ada Piutang', '$adaPiutang', Icons.assignment_late_outlined, AppTheme.green100, AppTheme.green700),
    ];

    if (isDesktop) {
      return Row(
        children: items.map((w) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 16), child: w))).toList()
          ..last = Expanded(child: items.last),
      );
    }
    return Column(
      children: items.map((w) => Padding(padding: const EdgeInsets.only(bottom: 12), child: w)).toList(),
    );
  }

  void _showBuyerDetails(BuildContext context, BuyerSummary buyer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Riwayat Transaksi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                        Text(buyer.name, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                      ],
                    )
                  ),
                  IconButton(
                    icon: const Icon(Icons.close), 
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(backgroundColor: Colors.grey.shade100),
                  ),
                ],
              ),
              const Divider(height: 32),
              Expanded(
                child: ListView(
                  children: [
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(2.5),
                        1: FlexColumnWidth(2),
                        2: FlexColumnWidth(3),
                        3: FlexColumnWidth(3.5),
                      },
                      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                      children: [
                        TableRow(
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1)),
                          ),
                          children: const [
                            Padding(
                              padding: EdgeInsets.only(bottom: 12.0),
                              child: Text('Tanggal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textSecondary)),
                            ),
                            Padding(
                              padding: EdgeInsets.only(bottom: 12.0),
                              child: Text('Jumlah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textSecondary)),
                            ),
                            Padding(
                              padding: EdgeInsets.only(bottom: 12.0),
                              child: Text('Harga/kg', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textSecondary)),
                            ),
                            Padding(
                              padding: EdgeInsets.only(bottom: 12.0),
                              child: Text('Total', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textSecondary)),
                            ),
                          ],
                        ),
                        ...buyer.sales.map((sale) {
                          return TableRow(
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: Color(0xFFF9FAFB), width: 1)),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16.0),
                                child: Text(sale.saleDate, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16.0),
                                child: Text('${sale.quantity} kg', style: const TextStyle(fontSize: 13)),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16.0),
                                child: Text('Rp ${ThousandsFormatter.format(sale.pricePerUnit.toString())}', style: const TextStyle(fontSize: 13)),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16.0),
                                child: Text('Rp ${ThousandsFormatter.format(sale.totalPrice.toString())}', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.green700, fontSize: 14)),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryTile(String label, String value, IconData icon, Color bg, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.people_outline, size: 70, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Belum ada data pembeli',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuyersGrid(bool isDesktop) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 2 : 1, // Using 2 columns for wider cards as per screenshot layout
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        mainAxisExtent: 180, // Fixed height for cards
      ),
      itemCount: _buyers.length,
      itemBuilder: (context, index) {
        final buyer = _buyers[index];
        final badgeColor = buyer.hasPiutang ? const Color(0xFF9A3412) : const Color(0xFF166534);
        final badgeBg = buyer.hasPiutang ? const Color(0xFFFFEDD5) : const Color(0xFFDCFCE7);
        final badgeText = buyer.hasPiutang ? 'Hutang' : 'Lunas';

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: () => _showBuyerDetails(context, buyer),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
              // Top Section (Avatar, Info, Actions)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.green700,
                    child: Text(
                      buyer.name.isNotEmpty ? buyer.name[0].toUpperCase() : 'P',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          buyer.name,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.phone_outlined, size: 14, color: AppTheme.textSecondary),
                            const SizedBox(width: 4),
                            Text(buyer.phone ?? 'Belum ada kontak', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                buyer.address != null && buyer.address!.isNotEmpty
                                    ? buyer.address!
                                    : 'Alamat tidak tersedia',
                                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Badges & Actions
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(12)),
                        child: Text(badgeText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: badgeColor)),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _deleteBuyer(buyer),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: AppTheme.red100, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.delete_outline, size: 16, color: AppTheme.red600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const Spacer(),
              const Divider(height: 1, color: Color(0xFFF3F4F6)),
              const Spacer(),
              
              // Bottom Section (Stats)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Transaksi', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text('${buyer.transactionCount}x', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Total Pembelian', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(_formatJt(buyer.totalSpent), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.green700)),
                    ],
                  ),
                ],
              ),
            ],
          ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Formatters ─────────────────────────────────────────────────────────────

  String _formatCurrency(int val) {
    return 'Rp ${val.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';
  }

  String _formatJt(int value) {
    if (value >= 1000000) {
      final double result = value / 1000000;
      return 'Rp ${result.toStringAsFixed(result.truncateToDouble() == result ? 0 : 1)} jt';
    }
    return _formatCurrency(value);
  }
}
