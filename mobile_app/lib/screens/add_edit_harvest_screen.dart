import 'package:flutter/material.dart';
import '../services/api_service.dart';

import '../models/harvest.dart';
import '../models/season.dart';
import '../widgets/app_theme.dart';
import 'package:intl/intl.dart';

class AddEditHarvestScreen extends StatefulWidget {
  final Harvest? harvest;
  final VoidCallback? onSaved;

  const AddEditHarvestScreen({
    this.harvest,
    this.onSaved,
    super.key,
  });

  @override
  State<AddEditHarvestScreen> createState() => _AddEditHarvestScreenState();
}

class _AddEditHarvestScreenState extends State<AddEditHarvestScreen> {
  late ApiService _apiService;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _dateController;
  late TextEditingController _weightController;
  late TextEditingController _notesController;
  // Komoditas is static, but we'll use a controller for the UI
  final TextEditingController _komoditasController = TextEditingController(text: 'Kentang');

  List<Season> _seasons = [];
  Season? _selectedSeason;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();

    // Format initial date if exists
    String initialDate = '';
    if (widget.harvest?.harvestDate != null && widget.harvest!.harvestDate.isNotEmpty) {
      try {
        final date = DateTime.parse(widget.harvest!.harvestDate);
        initialDate = DateFormat('dd/MM/yyyy').format(date);
      } catch (e) {
        initialDate = widget.harvest!.harvestDate;
      }
    } else {
       initialDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
    }

    _dateController = TextEditingController(text: initialDate);
    _weightController = TextEditingController(
      text: widget.harvest?.weightKg.toString() ?? '',
    );
    _notesController = TextEditingController(
      text: widget.harvest?.notes ?? '',
    );

    _loadSeasons();
  }

  Future<void> _loadSeasons() async {
    setState(() => _isLoading = true);

    try {
      final seasons = await _apiService.getSeasons();
      if (mounted) {
        setState(() {
          _seasons = seasons;
          if (widget.harvest != null) {
            _selectedSeason = _seasons.firstWhere(
              (s) => s.id == widget.harvest!.seasonId,
              orElse: () => _seasons.isNotEmpty ? _seasons.first : Season(
                id: 0,
                name: 'N/A',
                startDate: '',
                endDate: '',
                status: 'active',
              ),
            );
          } else if (_seasons.isNotEmpty) {
            _selectedSeason = _seasons.first;
          }
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

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now();
    try {
      initialDate = DateFormat('dd/MM/yyyy').parse(_dateController.text);
    } catch (_) {}

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
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
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _saveharvest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSeason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih blok kebun terlebih dahulu')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      // Parse date back to YYYY-MM-DD for API
      String apiDate = _dateController.text;
      try {
        final date = DateFormat('dd/MM/yyyy').parse(_dateController.text);
        apiDate = DateFormat('yyyy-MM-dd').format(date);
      } catch (_) {}

      final Map<String, dynamic> result;

      if (widget.harvest == null) {
        result = await _apiService.createHarvest(
          seasonId: _selectedSeason!.id,
          harvestDate: apiDate,
          quantity: 1, // Defaulting as it's removed from UI
          weightKg: double.parse(_weightController.text),
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          status: 'recorded', // Default status
        );
      } else {
        result = await _apiService.updateHarvest(
          widget.harvest!.id,
          seasonId: _selectedSeason!.id,
          harvestDate: apiDate,
          quantity: widget.harvest!.quantity > 0 ? widget.harvest!.quantity : 1,
          weightKg: double.parse(_weightController.text),
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          status: widget.harvest!.status, // Keep existing status
        );
      }

      setState(() => _isSaving = false);

      if (result['success'] == true) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(widget.harvest == null
                ? 'Panen berhasil ditambahkan'
                : 'Panen berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSaved?.call();
        navigator.pop(true);
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal menyimpan data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      messenger.showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    _komoditasController.dispose();
    super.dispose();
  }

  // ─── UI HELPER METHODS ─────────────────────────────────────────────────────

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: Color(0xFF1B4332), // Dark green text matching screenshot
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hintText, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFFA0AEC0), fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFFAF9F6), // Slightly off-white background
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.green700, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.harvest != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.green700))
          : SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(28.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isEdit ? 'Ubah Hasil Panen' : 'Catat Hasil Panen',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1B4332),
                                ),
                              ),
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.close, size: 18, color: Colors.black54),
                                  onPressed: () => Navigator.pop(context),
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // Row 1: Tanggal & Musim Tanam
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('Tanggal'),
                                    TextFormField(
                                      controller: _dateController,
                                      readOnly: true,
                                      onTap: () => _selectDate(context),
                                      style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                                      decoration: _inputDecoration(
                                        hintText: 'dd/mm/yyyy',
                                        suffixIcon: const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFFCBD5E1)),
                                      ),
                                      validator: (value) => value?.isEmpty ?? true ? 'Wajib diisi' : null,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('Musim Tanam'),
                                    DropdownButtonFormField<Season>(
                                      initialValue: _selectedSeason,
                                      icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFCBD5E1)),

                                      style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                                      decoration: _inputDecoration(hintText: 'Musim Tanam'),
                                      items: _seasons.map((season) => DropdownMenuItem(
                                        value: season,
                                        child: Text(season.name, style: const TextStyle(fontSize: 14)),
                                      )).toList(),
                                      onChanged: (Season? value) {
                                        setState(() => _selectedSeason = value);
                                      },
                                      validator: (value) => value == null ? 'Wajib dipilih' : null,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Row 2: Berat
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Berat (kg)'),
                              TextFormField(
                                controller: _weightController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                                decoration: _inputDecoration(hintText: '1200'),
                                validator: (value) {
                                  if (value?.isEmpty ?? true) return 'Wajib diisi';
                                  if (double.tryParse(value!) == null) return 'Angka tidak valid';
                                  return null;
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Row 3: Catatan
                          _buildLabel('Catatan'),
                          TextFormField(
                            controller: _notesController,
                            style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                            decoration: _inputDecoration(hintText: 'Opsional — kondisi hasil panen'),
                          ),
                          const SizedBox(height: 20),

                          const SizedBox(height: 32),

                          // Save Button
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.green700,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            onPressed: _isSaving ? null : _saveharvest,
                            child: _isSaving
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                  )
                                : const Text(
                                    'Simpan Data',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
    );
  }
}
