import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/cost.dart';
import '../models/season.dart';
import '../utils/thousands_formatter.dart';
import '../widgets/app_theme.dart';

class AddEditCostScreen extends StatefulWidget {
  final Cost? cost;
  final VoidCallback? onSaved;

  const AddEditCostScreen({super.key, this.cost, this.onSaved});

  @override
  State<AddEditCostScreen> createState() => _AddEditCostScreenState();
}

class _AddEditCostScreenState extends State<AddEditCostScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  
  late DateTime _selectedDate;
  int? _selectedSeasonId;
  String _selectedCategory = 'seed';
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  
  List<Season> _seasons = [];
  bool _isLoadingSeasons = true;
  bool _isSaving = false;

  final List<Map<String, String>> _categories = [
    {'value': 'seed', 'label': 'Bibit'},
    {'value': 'fertilizer', 'label': 'Pupuk'},
    {'value': 'pesticide', 'label': 'Pestisida'},
    {'value': 'other', 'label': 'Lainnya'},
  ];

  late TextEditingController _dateController;

  @override
  void initState() {
    super.initState();
    _selectedDate = (widget.cost != null && widget.cost!.date.isNotEmpty)
        ? (DateTime.tryParse(widget.cost!.date) ?? DateTime.now())
        : DateTime.now();
    _dateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(_selectedDate),
    );
    _selectedCategory = widget.cost?.category ?? 'seed';
    _selectedSeasonId = widget.cost?.seasonId;
    _amountController.text = widget.cost != null ? ThousandsFormatter.format(widget.cost!.amount.toStringAsFixed(0)) : '';
    _notesController.text = widget.cost?.notes ?? '';
    _loadSeasons();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadSeasons() async {
    try {
      final seasons = await _apiService.getSeasons();
      setState(() {
        _seasons = seasons;
        _isLoadingSeasons = false;
        if (widget.cost == null && _selectedSeasonId == null && seasons.isNotEmpty) {
          _selectedSeasonId = seasons.first.id;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingSeasons = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat daftar musim: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2D6A4F),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    
    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final amount = double.tryParse(_amountController.text.replaceAll('.', '')) ?? 0.0;
    
    final Map<String, dynamic> result;
    if (widget.cost != null) {
      result = await _apiService.updateCost(
        widget.cost!.id,
        date: formattedDate,
        seasonId: _selectedSeasonId,
        category: _selectedCategory,
        amount: amount,
        notes: _notesController.text.trim(),
      );
    } else {
      result = await _apiService.createCost(
        date: formattedDate,
        seasonId: _selectedSeasonId,
        category: _selectedCategory,
        amount: amount,
        notes: _notesController.text.trim(),
      );
    }

    setState(() => _isSaving = false);

    if (result['success'] == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.cost != null 
              ? 'Catatan biaya berhasil diperbarui!' 
              : 'Catatan biaya berhasil ditambahkan!'),
          backgroundColor: Colors.green,
        ),
      );
      widget.onSaved?.call();
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal menyimpan catatan biaya'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.cost != null;

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
              child: _isLoadingSeasons
                  ? const SizedBox(
                      height: 240,
                      child: Center(child: CircularProgressIndicator(color: Color(0xFF27AE60))),
                    )
                  : Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Title and Close button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isEdit ? 'Ubah Biaya Produksi' : 'Tambah Biaya Produksi',
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

                          // Row 1: Tanggal and Kategori side by side
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Tanggal',
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
                                        suffixIcon: Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                      ),
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
                                      'Kategori',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Color(0xFF1A3428),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      initialValue: _selectedCategory,
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      ),
                                      items: _categories
                                          .map(
                                            (c) => DropdownMenuItem<String>(
                                              value: c['value'],
                                              child: Text(c['label']!),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() => _selectedCategory = val);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Row 2: Deskripsi
                          const Text(
                            'Deskripsi',
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
                              hintText: 'Pupuk NPK 50 kg',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Deskripsi tidak boleh kosong';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Row 3: Jumlah (Rp)
                          const Text(
                            'Jumlah (Rp)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF1A3428),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [ThousandsFormatter()],
                            decoration: const InputDecoration(
                              hintText: '1500000',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Jumlah biaya tidak boleh kosong';
                              }
                              final cleanValue = value.replaceAll('.', '');
                              final val = double.tryParse(cleanValue);
                              if (val == null || val <= 0) {
                                return 'Jumlah biaya harus bernilai positif';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Row 4: Musim Tanam dropdown
                          const Text(
                            'Musim Tanam',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF1A3428),
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int?>(
                            initialValue: _selectedSeasonId,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('Tanpa Musim (Biaya Umum)'),
                              ),
                              ..._seasons.map(
                                (s) => DropdownMenuItem<int?>(
                                  value: s.id,
                                  child: Text(s.name),
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              setState(() => _selectedSeasonId = val);
                            },
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
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(50),
                                  ),
                                  onPressed: _isSaving ? null : _save,
                                  child: _isSaving
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : const Text(
                                          'Simpan',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
}
