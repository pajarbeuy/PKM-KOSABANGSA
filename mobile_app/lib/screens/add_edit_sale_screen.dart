import 'package:flutter/material.dart';
// intl removed: date input is text-only YYYY-MM-DD
import '../services/api_service.dart';
import '../models/sale.dart';
import '../utils/thousands_formatter.dart';
import '../widgets/app_theme.dart';

class AddEditSaleScreen extends StatefulWidget {
  final Sale? sale;
  final VoidCallback? onSaved;

  const AddEditSaleScreen({this.sale, this.onSaved, super.key});

  @override
  State<AddEditSaleScreen> createState() => _AddEditSaleScreenState();
}

class _AddEditSaleScreenState extends State<AddEditSaleScreen> {
  late ApiService _apiService;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _dateController;
  late TextEditingController _buyerNameController;
  late TextEditingController _buyerPhoneController;
  late TextEditingController _buyerAddressController;
  late TextEditingController _quantityController;
  late TextEditingController _pricePerUnitController;
  late TextEditingController _notesController;

  bool _isSaving = false;
  int? _totalPrice;
  late String _paymentStatus;

  Map<String, Map<String, String?>> _uniqueBuyers = {};
  List<String> _buyerNames = [];

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();

    _dateController = TextEditingController(text: widget.sale?.saleDate ?? '');
    _buyerNameController = TextEditingController(
      text: widget.sale?.buyerName ?? '',
    );
    _buyerPhoneController = TextEditingController(
      text: widget.sale?.buyerPhone ?? '',
    );
    _buyerAddressController = TextEditingController(
      text: widget.sale?.buyerAddress ?? '',
    );
    _quantityController = TextEditingController(
      text: widget.sale?.quantity.toString() ?? '',
    );
    _pricePerUnitController = TextEditingController(
      text: widget.sale?.pricePerUnit != null
          ? ThousandsFormatter.format(widget.sale!.pricePerUnit.toString())
          : '',
    );
    _notesController = TextEditingController(text: widget.sale?.notes ?? '');
    _paymentStatus = widget.sale?.status == 'pending' ? 'unpaid' : 'paid';

    _updateTotal();
    _loadBuyers();
  }

  Future<void> _loadBuyers() async {
    try {
      final sales = await _apiService.getSales();
      final Map<String, Map<String, String?>> buyers = {};
      
      for (var sale in sales) {
        final name = sale.buyerName.trim();
        if (name.isNotEmpty && !buyers.containsKey(name)) {
          buyers[name] = {
            'phone': sale.buyerPhone,
            'address': sale.buyerAddress,
          };
        } else if (name.isNotEmpty) {
          if (buyers[name]!['phone'] == null && sale.buyerPhone != null) {
            buyers[name]!['phone'] = sale.buyerPhone;
          }
          if (buyers[name]!['address'] == null && sale.buyerAddress != null) {
            buyers[name]!['address'] = sale.buyerAddress;
          }
        }
      }
      if (mounted) {
        setState(() {
          _uniqueBuyers = buyers;
          _buyerNames = buyers.keys.toList();
        });
      }
    } catch (e) {
      // ignore
    }
  }

  void _updateTotal() {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final price =
        int.tryParse(_pricePerUnitController.text.replaceAll('.', '')) ?? 0;
    setState(() {
      _totalPrice = quantity * price;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now();
    final DateTime firstDate = DateTime(2000);
    final DateTime lastDate = DateTime(2100);

    final DateTime? currentInputDate = DateTime.tryParse(_dateController.text);
    if (currentInputDate != null) {
      initialDate = currentInputDate;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF27AE60),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final String formatted =
          "${picked.year.toString().padLeft(4, '0')}-"
          "${picked.month.toString().padLeft(2, '0')}-"
          "${picked.day.toString().padLeft(2, '0')}";
      setState(() {
        _dateController.text = formatted;
      });
    }
  }

  Future<void> _saveSale() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final pricePerUnit =
        int.tryParse(_pricePerUnitController.text.replaceAll('.', '')) ?? 0;
    if (pricePerUnit > 0 && pricePerUnit < 1000) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Harga rendah'),
          content: const Text(
            'Harga per kg kurang dari Rp 1.000. Apakah Anda yakin ingin melanjutkan?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Lanjutkan'),
            ),
          ],
        ),
      );

      if (confirm != true) {
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final Map<String, dynamic> result;

      if (widget.sale == null) {
        // Create new
        result = await _apiService.createSale(
          quantity: int.parse(_quantityController.text),
          pricePerUnit: int.parse(
            _pricePerUnitController.text.replaceAll('.', ''),
          ),
          saleDate: _dateController.text,
          buyerName: _buyerNameController.text,
          buyerPhone: _buyerPhoneController.text.isEmpty
              ? null
              : _buyerPhoneController.text,
          buyerAddress: _buyerAddressController.text.isEmpty
              ? null
              : _buyerAddressController.text,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          status: 'completed',
          paymentStatus: _paymentStatus,
        );
      } else {
        // Edit existing
        result = await _apiService.updateSale(
          widget.sale!.id,
          quantity: int.parse(_quantityController.text),
          pricePerUnit: int.parse(
            _pricePerUnitController.text.replaceAll('.', ''),
          ),
          saleDate: _dateController.text,
          buyerName: _buyerNameController.text,
          buyerPhone: _buyerPhoneController.text.isEmpty
              ? null
              : _buyerPhoneController.text,
          buyerAddress: _buyerAddressController.text.isEmpty
              ? null
              : _buyerAddressController.text,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          status: 'completed',
          paymentStatus: _paymentStatus,
        );
      }

      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.sale == null
                    ? 'Penjualan berhasil ditambahkan'
                    : 'Penjualan berhasil diperbarui',
              ),
              backgroundColor: Colors.green,
            ),
          );
          widget.onSaved?.call();
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Gagal menyimpan data'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _buyerNameController.dispose();
    _buyerPhoneController.dispose();
    _buyerAddressController.dispose();
    _quantityController.dispose();
    _pricePerUnitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.sale != null;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 550),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppTheme.cardShadow,
              ),
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header: Title and Close button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEdit
                              ? 'Ubah Catatan Penjualan'
                              : 'Tambah Catatan Penjualan',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1B4332),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(context),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey.shade100,
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),


                    // Date
                    const Text(
                      'Tanggal Penjualan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1A3428),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _dateController,
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      decoration: const InputDecoration(
                        hintText: 'dd/mm/yyyy',
                        suffixIcon: Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: Colors.grey,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Tanggal harus diisi';
                        }
                        if (DateTime.tryParse(value!) == null) {
                          return 'Tanggal tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Buyer Name
                    const Text(
                      'Nama Pembeli',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1A3428),
                      ),
                    ),
                    const SizedBox(height: 8),
                    RawAutocomplete<String>(
                      textEditingController: _buyerNameController,
                      focusNode: FocusNode(),
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<String>.empty();
                        }
                        return _buyerNames.where((String option) {
                          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                        });
                      },
                      onSelected: (String selection) {
                        final info = _uniqueBuyers[selection];
                        if (info != null) {
                          if (info['phone'] != null && info['phone']!.isNotEmpty) {
                            _buyerPhoneController.text = info['phone']!;
                          }
                          if (info['address'] != null && info['address']!.isNotEmpty) {
                            _buyerAddressController.text = info['address']!;
                          }
                        }
                      },
                      fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                        return TextFormField(
                          controller: fieldTextEditingController,
                          focusNode: fieldFocusNode,
                          decoration: const InputDecoration(
                            hintText: 'Masukkan atau pilih nama pembeli...',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                          validator: (value) => value?.isEmpty ?? true
                              ? 'Nama pembeli harus diisi'
                              : null,
                        );
                      },
                      optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4.0,
                            borderRadius: BorderRadius.circular(8),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxHeight: 200, maxWidth: MediaQuery.of(context).size.width - 40),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final String option = options.elementAt(index);
                                  return InkWell(
                                    onTap: () => onSelected(option),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Text(option),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Buyer Phone
                    const Text(
                      'Nomor Telepon Pembeli',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1A3428),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _buyerPhoneController,
                      decoration: const InputDecoration(
                        hintText: 'Contoh: 081234567890 (Opsional)',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 20),

                    // Buyer Address
                    const Text(
                      'Alamat Pembeli',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1A3428),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _buyerAddressController,
                      decoration: const InputDecoration(
                        hintText: 'Contoh: Jl. Pertanian No. 12 (Opsional)',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),

                    // Quantity
                    const Text(
                      'Jumlah Terjual (Kg)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1A3428),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _quantityController,
                      onChanged: (_) => _updateTotal(),
                      decoration: const InputDecoration(
                        hintText: 'Masukkan berat kentang...',
                        suffixText: 'kg',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Jumlah harus diisi';
                        if (int.tryParse(value!) == null ||
                            int.parse(value) < 1) {
                          return 'Jumlah minimal 1';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Price Per Unit
                    const Text(
                      'Harga per Kg (Rp)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1A3428),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _pricePerUnitController,
                      onChanged: (_) => _updateTotal(),
                      inputFormatters: [ThousandsFormatter()],
                      decoration: const InputDecoration(
                        hintText: 'Contoh: 12.000',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Harga harus diisi';
                        final cleanValue = value!.replaceAll('.', '');
                        if (int.tryParse(cleanValue) == null ||
                            int.parse(cleanValue) < 0) {
                          return 'Harga tidak boleh negatif';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Total Price Display
                    if (_totalPrice != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Estimasi Total Pendapatan',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _formatCurrency(_totalPrice!),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Payment Status
                    const Text(
                      'Status Pembayaran',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1A3428),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _paymentStatus,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'paid', child: Text('Lunas')),
                        DropdownMenuItem(
                          value: 'unpaid',
                          child: Text('Belum Lunas'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _paymentStatus = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // Notes
                    const Text(
                      'Catatan / Keterangan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1A3428),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        hintText: 'Keterangan tambahan...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      maxLines: 3,
                      maxLength: 500,
                    ),
                    const SizedBox(height: 32),

                    // Action Buttons side-by-side
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Batal',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                            ),
                            onPressed: _isSaving ? null : _saveSale,
                            child: _isSaving
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Simpan',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatCurrency(int value) {
    return 'Rp ${(value).toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';
  }
}
