import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api_config.dart';
import '../models/processed_product.dart';
import '../services/api_service.dart';
import '../widgets/app_theme.dart';

class SuperAdminMarketingScreen extends StatefulWidget {
  final bool isEmbedded;
  final VoidCallback? onOpenOrders;
  const SuperAdminMarketingScreen({super.key, this.isEmbedded = false, this.onOpenOrders});

  @override
  State<SuperAdminMarketingScreen> createState() => _SuperAdminMarketingScreenState();
}

class _SuperAdminMarketingScreenState extends State<SuperAdminMarketingScreen> {
  final ApiService _apiService = ApiService();
  List<ProcessedProduct> _products = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = 'all';

  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final status = _statusFilter == 'all' ? null : _statusFilter;
      final products = await _apiService.getSuperAdminProcessedProducts(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        status: status,
      );
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat katalog pemasaran: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _toggleStatus(ProcessedProduct product) async {
    final newStatus = product.isInactive ? 'active' : 'inactive';
    final success = await _apiService.updateProductStatusBySuperAdmin(product.id, newStatus);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status "${product.name}" diubah menjadi $newStatus'),
          backgroundColor: AppTheme.green700,
        ),
      );
      _loadProducts();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memperbarui status produk'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadProducts,
      color: AppTheme.green700,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header description
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.green700.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.green700.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.storefront_outlined, color: AppTheme.green700, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pusat Pemasaran Produk Olahan Tani',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.dark900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Pantau dan kelola publikasi produk olahan dari seluruh petani mitra untuk ditampilkan di Katalog Web publik.',
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                  if (widget.onOpenOrders != null) ...[
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: widget.onOpenOrders,
                      icon: const Icon(Icons.receipt_long_rounded, size: 16, color: Colors.white),
                      label: const Text(
                        'Pesanan Masuk',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.green700,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search and filter
            TextField(
              decoration: InputDecoration(
                hintText: 'Cari nama produk atau petani...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              onChanged: (val) {
                _searchQuery = val;
                _loadProducts();
              },
            ),
            const SizedBox(height: 12),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('all', 'Semua'),
                  const SizedBox(width: 8),
                  _filterChip('active', 'Aktif (Katalog)'),
                  const SizedBox(width: 8),
                  _filterChip('out_of_stock', 'Stok Habis'),
                  const SizedBox(width: 8),
                  _filterChip('inactive', 'Nonaktif'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: AppTheme.green700),
                ),
              )
            else if (_products.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 56, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      const Text(
                        'Belum Ada Produk Terdaftar',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Petani mitra belum mendaftarkan produk olahan.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _products.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) {
                  final p = _products[i];
                  return _buildProductCard(p);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String key, String label) {
    final isSelected = _statusFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _statusFilter = key);
          _loadProducts();
        }
      },
      selectedColor: AppTheme.green700,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }

  Widget _buildProductCard(ProcessedProduct p) {
    Color badgeBg;
    Color badgeTextColor;
    String badgeText;

    if (p.isActive) {
      badgeBg = Colors.green[50]!;
      badgeTextColor = Colors.green[800]!;
      badgeText = 'Aktif (Tampil di Katalog)';
    } else if (p.isOutOfStock) {
      badgeBg = Colors.amber[50]!;
      badgeTextColor = Colors.amber[900]!;
      badgeText = 'Stok Habis (Tampil)';
    } else {
      badgeBg = Colors.grey[100]!;
      badgeTextColor = Colors.grey[700]!;
      badgeText = 'Nonaktif (Disembunyikan)';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: (p.photoUrl != null && p.photoUrl!.isNotEmpty)
                ? () {
                    showDialog(
                      context: context,
                      builder: (ctx) => Dialog(
                        backgroundColor: Colors.transparent,
                        child: Stack(
                          alignment: Alignment.topRight,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                ApiConfig.resolveUrl(p.photoUrl!),
                                fit: BoxFit.contain,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => Navigator.pop(ctx),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                : null,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.green700.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: (p.photoUrl != null && p.photoUrl!.isNotEmpty)
                    ? Image.network(
                        ApiConfig.resolveUrl(p.photoUrl!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.shopping_bag_outlined, color: AppTheme.green700, size: 28),
                      )
                    : const Icon(Icons.shopping_bag_outlined, color: AppTheme.green700, size: 28),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        p.name,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.dark900),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(12)),
                      child: Text(badgeText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeTextColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Petani: ${p.ownerName} (${p.farmName ?? "Kebun Tani"})',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _currencyFormat.format(p.price),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.green700),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Sisa Stok: ${p.stock} unit',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: p.stock > 0 ? Colors.grey[800] : Colors.red[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: p.isInactive ? 'Aktifkan Produk' : 'Nonaktifkan Produk',
            icon: Icon(
              p.isInactive ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: p.isInactive ? Colors.grey : AppTheme.green700,
            ),
            onPressed: () => _toggleStatus(p),
          ),
        ],
      ),
    );
  }
}
