import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/harvest.dart';
import '../models/processed_product.dart';
import '../services/api_service.dart';
import 'app_theme.dart';

class ConvertHarvestDialog extends StatefulWidget {
  final Harvest? initialHarvest;
  final ProcessedProduct? initialProduct;
  final VoidCallback onConverted;

  const ConvertHarvestDialog({
    super.key,
    this.initialHarvest,
    this.initialProduct,
    required this.onConverted,
  });

  @override
  State<ConvertHarvestDialog> createState() => _ConvertHarvestDialogState();
}

class _CostItemRow {
  String category;
  TextEditingController nameController;
  TextEditingController qtyController;
  TextEditingController unitController;
  TextEditingController priceController;

  _CostItemRow({
    this.category = 'raw_material_addon',
    String name = '',
    String qty = '',
    String unit = 'kg',
    String price = '',
  })  : nameController = TextEditingController(text: name),
        qtyController = TextEditingController(text: qty),
        unitController = TextEditingController(text: unit),
        priceController = TextEditingController(text: price);

  double get subtotal {
    final q = double.tryParse(qtyController.text) ?? 0.0;
    final p = double.tryParse(priceController.text) ?? 0.0;
    return q * p;
  }

  void dispose() {
    nameController.dispose();
    qtyController.dispose();
    unitController.dispose();
    priceController.dispose();
  }
}

class _ConvertHarvestDialogState extends State<ConvertHarvestDialog> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  List<Harvest> _availableHarvests = [];
  List<ProcessedProduct> _availableProducts = [];
  Harvest? _selectedHarvest;
  ProcessedProduct? _selectedProduct;

  bool _isLoadingData = true;
  bool _isSubmitting = false;

  final TextEditingController _rawWeightController = TextEditingController();
  final TextEditingController _additionalStockController = TextEditingController();

  final List<_CostItemRow> _costItems = [];

  final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadPrerequisites();
  }

  @override
  void dispose() {
    _rawWeightController.dispose();
    _additionalStockController.dispose();
    for (final item in _costItems) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPrerequisites() async {
    setState(() => _isLoadingData = true);
    try {
      final harvests = await _apiService.getHarvests();
      final products = await _apiService.getFarmerProcessedProducts();

      setState(() {
        _availableHarvests = harvests;
        _availableProducts = products;

        if (widget.initialHarvest != null) {
          _selectedHarvest = harvests.firstWhere(
            (h) => h.id == widget.initialHarvest!.id,
            orElse: () => widget.initialHarvest!,
          );
        } else if (_availableHarvests.isNotEmpty) {
          _selectedHarvest = _availableHarvests.first;
        }

        if (widget.initialProduct != null) {
          _selectedProduct = products.firstWhere(
            (p) => p.id == widget.initialProduct!.id,
            orElse: () => widget.initialProduct!,
          );
        } else if (_availableProducts.isNotEmpty) {
          _selectedProduct = _availableProducts.first;
        }

        _isLoadingData = false;
      });
    } catch (_) {
      setState(() => _isLoadingData = false);
    }
  }

  void _addCostItem({String name = '', String category = 'raw_material_addon', String unit = 'kg'}) {
    setState(() {
      _costItems.add(_CostItemRow(name: name, category: category, unit: unit));
    });
  }

  void _removeCostItem(int index) {
    setState(() {
      _costItems[index].dispose();
      _costItems.removeAt(index);
    });
  }

  double get _totalAuxiliaryCost {
    double total = 0.0;
    for (final item in _costItems) {
      total += item.subtotal;
    }
    return total;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedHarvest == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih hasil panen yang akan dialihkan.'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih produk olahan tujuan.'), backgroundColor: Colors.red),
      );
      return;
    }

    final rawWeight = double.tryParse(_rawWeightController.text) ?? 0.0;
    final additionalStock = int.tryParse(_additionalStockController.text) ?? 0;

    final formattedCostItems = _costItems.map((item) {
      final qty = double.tryParse(item.qtyController.text) ?? 0.0;
      final price = double.tryParse(item.priceController.text) ?? 0.0;
      return {
        'category': item.category,
        'item_name': item.nameController.text.trim(),
        'quantity': qty,
        'unit': item.unitController.text.trim(),
        'price_per_unit': price,
        'amount': qty * price,
        'date': DateTime.now().toIso8601String().substring(0, 10),
      };
    }).where((item) => (item['amount'] as double) > 0).toList();

    setState(() => _isSubmitting = true);

    try {
      final res = await _apiService.convertHarvestToProcessedProduct(
        productId: _selectedProduct!.id,
        harvestId: _selectedHarvest!.id,
        rawMaterialWeightKg: rawWeight,
        additionalStock: additionalStock,
        costItems: formattedCostItems,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (res['success'] == true) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Bahan baku panen berhasil dialihkan ke produk olahan!'),
            backgroundColor: AppTheme.green700,
          ),
        );
        widget.onConverted();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Gagal mengonversi hasil panen'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 700;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 680,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: _isLoadingData
            ? const SizedBox(
                height: 250,
                child: Center(child: CircularProgressIndicator(color: AppTheme.green700)),
              )
            : Form(
                key: _formKey,
                child: Column(
                  children: [
                    // ── Header ──────────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      decoration: const BoxDecoration(
                        color: AppTheme.green700,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.soup_kitchen_outlined, color: Colors.white, size: 24),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Alihkan Panen ke Produk Olahan',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Integrasikan hasil kebun & modal bahan olahan tanpa double-counting',
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

                    // ── Scrollable Body ─────────────────────────────────────
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Zero Double-Counting Info Callout ───────────
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF), // Blue 50
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFBFDBFE)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.info_outline, color: Color(0xFF1D4ED8), size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: RichText(
                                      text: const TextSpan(
                                        style: TextStyle(fontSize: 12, color: Color(0xFF1E3A8A), height: 1.4),
                                        children: [
                                          TextSpan(
                                            text: 'Aturan Bebas Biaya Ganda: ',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          TextSpan(
                                            text:
                                                'Bahan baku panen yang dialihkan bernilai modal tunai Rp 0 pada produk olahan karena biaya budidaya telah dicatat penuh di modal kebun. Anda hanya perlu menginput modal bahan penolong (tepung, minyak, packaging, dll.).',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ── Pilihan Hasil Panen ──────────────────────────
                            const Text(
                              'Hasil Panen Asal (Bahan Baku)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 8),
                            if (_availableHarvests.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.orange.shade200),
                                ),
                                child: const Text(
                                  'Belum ada catatan panen di sistem. Silakan catat panen terlebih dahulu.',
                                  style: TextStyle(fontSize: 13, color: Colors.orange),
                                ),
                              )
                            else
                              DropdownButtonFormField<Harvest>(
                                value: _selectedHarvest,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  prefixIcon: const Icon(Icons.agriculture, color: AppTheme.green700, size: 20),
                                ),
                                items: _availableHarvests.map((h) {
                                  final commodity = h.commodityName ?? 'Komoditas';
                                  final date = h.harvestDate;
                                  return DropdownMenuItem(
                                    value: h,
                                    child: Text(
                                      '$commodity — ${h.weightKg} kg ($date)',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedHarvest = val;
                                  });
                                },
                              ),
                            const SizedBox(height: 18),

                            // ── Pilihan Produk Olahan ────────────────────────
                            const Text(
                              'Produk Olahan Tujuan',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 8),
                            if (_availableProducts.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: const Text(
                                  'Belum ada data produk olahan. Silakan buat produk olahan (misal Jamur Crispy / Keripik) terlebih dahulu di menu Produk Olahan.',
                                  style: TextStyle(fontSize: 13, color: Colors.red),
                                ),
                              )
                            else
                              DropdownButtonFormField<ProcessedProduct>(
                                value: _selectedProduct,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  prefixIcon: const Icon(Icons.storefront_outlined, color: AppTheme.green700, size: 20),
                                ),
                                items: _availableProducts.map((p) {
                                  return DropdownMenuItem(
                                    value: p,
                                    child: Text(
                                      '${p.name} (Stok: ${p.stock} ${p.unit} @ ${_currencyFormat.format(p.price)})',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedProduct = val;
                                  });
                                },
                              ),
                            const SizedBox(height: 18),

                            // ── Bobot yang Dialihkan & Hasil Tambahan Stok ──
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Bobot Panen Dialihkan (kg) *',
                                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                      ),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: _rawWeightController,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: InputDecoration(
                                          hintText: 'Misal: 15.0',
                                          suffixText: 'kg',
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Wajib diisi';
                                          final n = double.tryParse(val);
                                          if (n == null || n <= 0) return 'Harus > 0';
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Tambah Stok Olahan (Pcs) *',
                                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                      ),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: _additionalStockController,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          hintText: 'Misal: 150',
                                          suffixText: _selectedProduct?.unit ?? 'pcs',
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Wajib diisi';
                                          final n = int.tryParse(val);
                                          if (n == null || n < 0) return 'Harus >= 0';
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // ── Modal Bahan Penolong (Tepung, Minyak, dll.) ──
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Modal Bahan Penolong Tambahan',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Tepung, minyak goreng, bumbu, plastik standing pouch, gas/listrik',
                                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                    ),
                                  ],
                                ),
                                TextButton.icon(
                                  onPressed: () => _addCostItem(name: '', unit: 'kg'),
                                  icon: const Icon(Icons.add_circle_outline, size: 16),
                                  label: const Text('Tambah Bahan', style: TextStyle(fontWeight: FontWeight.bold)),
                                  style: TextButton.styleFrom(foregroundColor: AppTheme.green700),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            if (_costItems.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(Icons.inventory_2_outlined, color: Colors.grey.shade400, size: 28),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'Belum ada rincian bahan penolong tambahan.',
                                        style: TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 8,
                                        children: [
                                          ActionChip(
                                            label: const Text('+ Tepung Terigu'),
                                            onPressed: () => _addCostItem(name: 'Tepung Terigu', unit: 'kg'),
                                          ),
                                          ActionChip(
                                            label: const Text('+ Minyak Goreng'),
                                            onPressed: () => _addCostItem(name: 'Minyak Goreng', unit: 'liter'),
                                          ),
                                          ActionChip(
                                            label: const Text('+ Kemasan Pouch'),
                                            onPressed: () => _addCostItem(name: 'Standing Pouch', category: 'packaging', unit: 'pcs'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _costItems.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (context, idx) {
                                  final item = _costItems[idx];
                                  return Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: TextFormField(
                                                controller: item.nameController,
                                                decoration: const InputDecoration(
                                                  labelText: 'Nama Bahan',
                                                  hintText: 'Misal: Tepung Terigu',
                                                  isDense: true,
                                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                                ),
                                                validator: (v) => v == null || v.isEmpty ? 'Isi nama' : null,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              flex: 2,
                                              child: DropdownButtonFormField<String>(
                                                value: item.category,
                                                isExpanded: true,
                                                decoration: const InputDecoration(
                                                  labelText: 'Kategori',
                                                  isDense: true,
                                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                                ),
                                                items: const [
                                                  DropdownMenuItem(value: 'raw_material_addon', child: Text('Bahan Tambahan', style: TextStyle(fontSize: 12))),
                                                  DropdownMenuItem(value: 'packaging', child: Text('Kemasan', style: TextStyle(fontSize: 12))),
                                                  DropdownMenuItem(value: 'utility', child: Text('Utilitas (Gas/Listrik)', style: TextStyle(fontSize: 12))),
                                                  DropdownMenuItem(value: 'labor', child: Text('Upah Tenaga', style: TextStyle(fontSize: 12))),
                                                  DropdownMenuItem(value: 'other', child: Text('Lainnya', style: TextStyle(fontSize: 12))),
                                                ],
                                                onChanged: (cat) {
                                                  if (cat != null) setState(() => item.category = cat);
                                                },
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                              onPressed: () => _removeCostItem(idx),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: TextFormField(
                                                controller: item.qtyController,
                                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                decoration: const InputDecoration(
                                                  labelText: 'Jumlah',
                                                  hintText: '2',
                                                  isDense: true,
                                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                                ),
                                                onChanged: (_) => setState(() {}),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              flex: 2,
                                              child: TextFormField(
                                                controller: item.unitController,
                                                decoration: const InputDecoration(
                                                  labelText: 'Satuan',
                                                  hintText: 'kg / liter',
                                                  isDense: true,
                                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              flex: 3,
                                              child: TextFormField(
                                                controller: item.priceController,
                                                keyboardType: TextInputType.number,
                                                decoration: const InputDecoration(
                                                  labelText: 'Harga / Satuan',
                                                  hintText: '10000',
                                                  prefixText: 'Rp ',
                                                  isDense: true,
                                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                                ),
                                                onChanged: (_) => setState(() {}),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              flex: 3,
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  const Text('Subtotal', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                                  Text(
                                                    _currencyFormat.format(item.subtotal),
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 13,
                                                      color: AppTheme.green800,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            const SizedBox(height: 16),

                            // ── Total Modal Card ────────────────────────────
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4), // Green 50
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFBBF7D0)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total Modal Bahan Penolong:',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF166534)),
                                  ),
                                  Text(
                                    _currencyFormat.format(_totalAuxiliaryCost),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      color: Color(0xFF15803D),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Footer Action Buttons ───────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border(top: BorderSide(color: Colors.grey.shade200)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                            child: const Text('Batal'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _isSubmitting || _availableProducts.isEmpty || _availableHarvests.isEmpty
                                ? null
                                : _submit,
                            icon: _isSubmitting
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.check_circle_outline, size: 18),
                            label: Text(_isSubmitting ? 'Memproses...' : 'Konversi & Catat Modal'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.green700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
