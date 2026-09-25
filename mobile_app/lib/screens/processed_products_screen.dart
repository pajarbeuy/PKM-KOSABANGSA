import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../api_config.dart';
import '../models/processed_product.dart';
import '../services/api_service.dart';
import '../widgets/app_shell.dart';
import '../widgets/app_theme.dart';
import '../widgets/convert_harvest_dialog.dart';
import '../widgets/integrated_economic_dialog.dart';
import '../widgets/processed_economic_dialog.dart';

class ProcessedProductsScreen extends StatefulWidget {
  const ProcessedProductsScreen({super.key});

  @override
  State<ProcessedProductsScreen> createState() => _ProcessedProductsScreenState();
}

class _ProcessedProductsScreenState extends State<ProcessedProductsScreen> {
  final ApiService _apiService = ApiService();
  List<ProcessedProduct> _products = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatusFilter = 'all';

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
      final status = _selectedStatusFilter == 'all' ? null : _selectedStatusFilter;
      final products = await _apiService.getFarmerProcessedProducts(
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
        SnackBar(content: Text('Gagal memuat produk: $e'), backgroundColor: Colors.red),
      );
    }
  }

  int get _totalStock => _products.fold(0, (sum, p) => sum + p.stock);
  int get _activeCount => _products.where((p) => p.isActive).length;
  int get _outOfStockCount => _products.where((p) => p.isOutOfStock).length;

  void _showAddEditBottomSheet({ProcessedProduct? product}) {
    final isEditing = product != null;
    final nameController = TextEditingController(text: product?.name ?? '');
    final priceController = TextEditingController(text: product != null ? product.price.toStringAsFixed(0) : '');
    final stockController = TextEditingController(text: product?.stock.toString() ?? '0');
    final descController = TextEditingController(text: product?.description ?? '');
    String status = product?.status ?? 'active';
    String unit = product?.unit ?? 'pcs';

    XFile? selectedPhotoFile;
    Uint8List? selectedPhotoBytes;
    final ImagePicker picker = ImagePicker();

    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isEditing ? 'Edit Produk Olahan' : 'Tambah Produk Olahan',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.dark900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Produk ini akan ditampilkan di katalog untuk dipasarkan oleh Super Admin.',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 20),

                    // Foto Produk
                    InkWell(
                      onTap: () async {
                        final picked = await picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 1200,
                          maxHeight: 1200,
                          imageQuality: 85,
                        );
                        if (picked != null) {
                          final bytes = await picked.readAsBytes();
                          setModalState(() {
                            selectedPhotoFile = picked;
                            selectedPhotoBytes = bytes;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[300]!, width: 1.5),
                        ),
                        child: selectedPhotoBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.memory(selectedPhotoBytes!, fit: BoxFit.cover),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () => setModalState(() {
                                          selectedPhotoFile = null;
                                          selectedPhotoBytes = null;
                                        }),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close, color: Colors.white, size: 18),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 8,
                                      left: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.check_circle, color: Colors.greenAccent, size: 14),
                                            SizedBox(width: 4),
                                            Text('Foto Dipilih', style: TextStyle(color: Colors.white, fontSize: 11)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : (product?.photoUrl != null && product!.photoUrl!.isNotEmpty)
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.network(
                                          ApiConfig.resolveUrl(product.photoUrl!),
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => const Center(
                                            child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 8,
                                          right: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.photo_camera_outlined, color: Colors.white, size: 14),
                                                SizedBox(width: 4),
                                                Text('Ganti Foto', style: TextStyle(color: Colors.white, fontSize: 11)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: AppTheme.green700.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.add_a_photo_outlined, color: AppTheme.green700, size: 22),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Pilih Foto Produk',
                                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.green700),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Klik untuk ambil dari galeri (Maks. 4MB)',
                                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                      ),
                                    ],
                                  ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nama Produk
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Nama Produk *',
                        hintText: 'Contoh: Keripik Jamur Crispy',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.shopping_bag_outlined),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama produk wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),

                    // Harga
                    TextFormField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Harga (Rp) *',
                        hintText: '25000',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.attach_money),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Harga wajib diisi';
                        final val = double.tryParse(v);
                        if (val == null || val < 0) return 'Harga tidak valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Stok & Satuan
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: stockController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Stok *',
                              hintText: '50',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              prefixIcon: const Icon(Icons.inventory_2_outlined),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Stok wajib diisi';
                              final val = int.tryParse(v);
                              if (val == null || val < 0) return 'Stok tidak valid';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            initialValue: unit,
                            decoration: InputDecoration(
                              labelText: 'Satuan *',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'pcs', child: Text('pcs')),
                              DropdownMenuItem(value: 'kg', child: Text('kg')),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => unit = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Status
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: InputDecoration(
                        labelText: 'Status Produk',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.toggle_on_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'active', child: Text('Aktif (Bisa Dipesan)')),
                        DropdownMenuItem(value: 'out_of_stock', child: Text('Stok Habis')),
                        DropdownMenuItem(value: 'inactive', child: Text('Nonaktif (Sembunyikan)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => status = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Deskripsi
                    TextFormField(
                      controller: descController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Deskripsi Produk (Opsional)',
                        hintText: 'Jelaskan keunggulan rasa, berat kemasan, atau bahan baku.',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSaving ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Batal'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) return;
                                    setModalState(() => isSaving = true);

                                    final price = double.parse(priceController.text);
                                    final stock = int.parse(stockController.text);
                                    final messenger = ScaffoldMessenger.of(context);
                                    final navigator = Navigator.of(ctx);

                                    Map<String, dynamic> result;
                                    if (isEditing) {
                                      result = await _apiService.updateProcessedProduct(
                                        product.id,
                                        name: nameController.text.trim(),
                                        price: price,
                                        stock: stock,
                                        unit: unit,
                                        description: descController.text.trim(),
                                        status: status,
                                        photoFile: selectedPhotoFile,
                                      );
                                    } else {
                                      result = await _apiService.createProcessedProduct(
                                        name: nameController.text.trim(),
                                        price: price,
                                        stock: stock,
                                        unit: unit,
                                        description: descController.text.trim(),
                                        status: status,
                                        photoFile: selectedPhotoFile,
                                      );
                                    }

                                    setModalState(() => isSaving = false);
                                    if (!mounted) return;

                                    navigator.pop();
                                    if (result['success'] == true) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(result['message'] ?? 'Berhasil disimpan!'),
                                          backgroundColor: AppTheme.green700,
                                        ),
                                      );
                                      _loadProducts();
                                    } else {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(result['message'] ?? 'Gagal menyimpan'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.green700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(isEditing ? 'Simpan Perubahan' : 'Tambah Produk'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(ProcessedProduct product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Produk Olahan'),
        content: Text('Apakah Anda yakin ingin menghapus "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await _apiService.deleteProcessedProduct(product.id);
              if (!mounted) return;
              if (ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Produk olahan berhasil dihapus'), backgroundColor: AppTheme.green700),
                );
                _loadProducts();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Gagal menghapus produk olahan'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: 'processed_products',
      title: 'Produk Olahan',
      subtitle: 'Kelola inventori dan ragam produk olahan hasil tani mandiri',
      onRefresh: _loadProducts,
      headerActions: [
        OutlinedButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => const IntegratedEconomicDialog(),
            );
          },
          icon: const Icon(Icons.account_balance_wallet_outlined, size: 16),
          label: const Text('Laba/Rugi Terpadu', style: TextStyle(fontWeight: FontWeight.bold)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.green700,
            side: const BorderSide(color: AppTheme.green700),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => ConvertHarvestDialog(onConverted: _loadProducts),
            );
          },
          icon: const Icon(Icons.soup_kitchen_outlined, size: 16),
          label: const Text('Alihkan Panen', style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.shade800,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditBottomSheet(),
        backgroundColor: AppTheme.green700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Produk'),
      ),
      child: RefreshIndicator(
        onRefresh: _loadProducts,
        color: AppTheme.green700,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Alihkan Panen & Laba Terpadu
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE65100), Color(0xFFF57C00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.soup_kitchen_outlined, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Buat Olahan dari Hasil Panen',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Bahan baku Rp 0 (hemat modal), catat bahan pelengkap & margin laba',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => ConvertHarvestDialog(onConverted: _loadProducts),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFE65100),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: const Text('Alihkan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ),
              // Summary Stats Row
              _buildStatsRow(),
              const SizedBox(height: 20),

              // Filter & Search Bar
              _buildFilterBar(),
              const SizedBox(height: 20),

              // Product List
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(color: AppTheme.green700),
                  ),
                )
              else if (_products.isEmpty)
                _buildEmptyState()
              else
                _buildProductGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatCard('Total Produk', '${_products.length}', Icons.category_outlined, Colors.blue),
        const SizedBox(width: 12),
        _buildStatCard('Total Stok', '$_totalStock unit', Icons.inventory_2_outlined, AppTheme.green700),
        const SizedBox(width: 12),
        _buildStatCard('Aktif', '$_activeCount', Icons.check_circle_outline, Colors.teal),
        const SizedBox(width: 12),
        _buildStatCard('Stok Habis', '$_outOfStockCount', Icons.warning_amber_rounded, Colors.orange),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.dark900)),
            const SizedBox(height: 2),
            Text(title, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'Cari produk olahan...',
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
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
              _buildFilterChip('all', 'Semua Status'),
              const SizedBox(width: 8),
              _buildFilterChip('active', 'Aktif'),
              const SizedBox(width: 8),
              _buildFilterChip('out_of_stock', 'Stok Habis'),
              const SizedBox(width: 8),
              _buildFilterChip('inactive', 'Nonaktif'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedStatusFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedStatusFilter = key);
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Produk Olahan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.dark900),
            ),
            const SizedBox(height: 8),
            Text(
              'Tekan tombol Tambah Produk di bawah untuk mulai mencatat produk olahan Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWide ? 2 : 1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 385,
          ),
          itemCount: _products.length,
          itemBuilder: (context, index) {
            final product = _products[index];
            return _buildProductCard(product);
          },
        );
      },
    );
  }

  void _showImagePreviewDialog(String imageUrl, String productName) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.7,
                      ),
                      child: InteractiveViewer(
                        child: Image.network(
                          ApiConfig.resolveUrl(imageUrl),
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const SizedBox(
                              height: 250,
                              child: Center(
                                child: CircularProgressIndicator(color: Colors.white),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => const SizedBox(
                            height: 200,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image, size: 48, color: Colors.white54),
                                  SizedBox(height: 8),
                                  Text('Gagal memuat gambar', style: TextStyle(color: Colors.white70)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E293B),
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                    ),
                    child: Text(
                      productName,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
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
                  child: const Icon(Icons.close, color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(ProcessedProduct product) {
    Color badgeBg;
    Color badgeTextColor;
    String badgeText;

    if (product.isActive) {
      badgeBg = const Color(0xFFE8F5E9);
      badgeTextColor = const Color(0xFF2E7D32);
      badgeText = 'Tersedia (${product.stock} ${product.unit})';
    } else if (product.isOutOfStock) {
      badgeBg = const Color(0xFFFFF3E0);
      badgeTextColor = const Color(0xFFE65100);
      badgeText = 'Stok Habis';
    } else {
      badgeBg = const Color(0xFFF5F5F5);
      badgeTextColor = const Color(0xFF616161);
      badgeText = 'Nonaktif';
    }

    final hasPhoto = product.photoUrl != null && product.photoUrl!.isNotEmpty;
    final resolvedUrl = ApiConfig.resolveUrl(product.photoUrl);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Image Area
          GestureDetector(
            onTap: hasPhoto ? () => _showImagePreviewDialog(product.photoUrl!, product.name) : null,
            child: Container(
              height: 140,
              width: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                color: Color(0xFFF1F5F9),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    child: hasPhoto
                        ? Image.network(
                            resolvedUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: progress.expectedTotalBytes != null
                                      ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                      : null,
                                  color: AppTheme.green700,
                                  strokeWidth: 2,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: const Color(0xFFF8FAFC),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.fastfood_outlined, color: AppTheme.green700, size: 36),
                                  SizedBox(height: 4),
                                  Text('Foto Produk', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                ],
                              ),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.green700.withValues(alpha: 0.08),
                                  AppTheme.green700.withValues(alpha: 0.02),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.fastfood_outlined, color: AppTheme.green700, size: 38),
                                SizedBox(height: 4),
                                Text('Belum ada foto', style: TextStyle(color: Colors.grey, fontSize: 11)),
                              ],
                            ),
                          ),
                  ),
                  // Floating Status Badge on top-right
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
                        ],
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeTextColor),
                      ),
                    ),
                  ),
                  // Price Tag on bottom-left
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_currencyFormat.format(product.price)} / ${product.unit}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  // Zoom icon indicator on top-left if photo exists
                  if (hasPhoto)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.fullscreen, color: Colors.white, size: 16),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Content Details Area
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.dark900),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  product.description?.isNotEmpty == true ? product.description! : 'Tidak ada deskripsi.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (product.harvestId != null || (product.rawMaterialWeightKg != null && product.rawMaterialWeightKg! > 0)) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFFCC80)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.soup_kitchen_outlined, size: 12, color: Color(0xFFE65100)),
                        const SizedBox(width: 4),
                        Text(
                          'Bahan Baku Panen: ${product.rawMaterialWeightKg ?? 0} kg',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFE65100)),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Modal: ${_currencyFormat.format(product.totalProcessingCost ?? 0)}',
                              style: TextStyle(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              (product.profitLoss ?? 0) >= 0
                                  ? 'Laba: +${_currencyFormat.format(product.profitLoss ?? 0)}'
                                  : 'Rugi: ${_currencyFormat.format(product.profitLoss ?? 0)}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: (product.profitLoss ?? 0) >= 0 ? const Color(0xFF2E7D32) : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () => showDialog(
                          context: context,
                          builder: (_) => ProcessedEconomicDialog(product: product),
                        ),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.green700.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.analytics_outlined, size: 12, color: AppTheme.green700),
                              SizedBox(width: 4),
                              Text('Analisis', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.green700)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${product.stock} ${product.unit}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => _showAddEditBottomSheet(product: product),
                          icon: const Icon(Icons.edit_outlined, size: 15),
                          label: const Text('Edit', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.green700,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () => _confirmDelete(product),
                          icon: const Icon(Icons.delete_outline, size: 15),
                          label: const Text('Hapus', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red[600],
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
