import 'package:flutter/material.dart';
import '../../models/season.dart';
import '../../services/api_service.dart';
import '../app_theme.dart';

/// Modal bottom sheet form for creating or editing a Season.
/// Extracted from season_screen.dart to eliminate god-screen spaghetti code.
class SeasonFormBottomSheet extends StatefulWidget {
  final ApiService apiService;
  final Season? season;
  final List<Season> existingSeasons;
  final Function(Season) onSuccess;

  const SeasonFormBottomSheet({
    super.key,
    required this.apiService,
    this.season,
    required this.existingSeasons,
    required this.onSuccess,
  });

  @override
  State<SeasonFormBottomSheet> createState() => _SeasonFormBottomSheetState();
}

class _SeasonFormBottomSheetState extends State<SeasonFormBottomSheet> {
  late TextEditingController _nameController;
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;
  late TextEditingController _targetKgController;
  late TextEditingController _notesController;
  String _status = 'active';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.season?.name ?? '');
    _startDateController = TextEditingController(text: widget.season?.startDate ?? '');
    _endDateController = TextEditingController(text: widget.season?.endDate ?? '');
    _notesController = TextEditingController(text: widget.season?.notes ?? '');
    _targetKgController = TextEditingController(
      text: widget.season != null ? widget.season!.targetKg.toString() : '',
    );
    _status = widget.season?.status ?? 'active';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _targetKgController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('id', 'ID'),
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        controller.text = picked.toString().split(' ')[0];
      });
    }
  }

  Future<void> _submitForm() async {
    if (_nameController.text.isEmpty ||
        _startDateController.text.isEmpty ||
        _endDateController.text.isEmpty ||
        _targetKgController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua field harus diisi')),
      );
      return;
    }

    final normalizedName = _nameController.text.trim().toLowerCase();
    final hasDuplicateName = widget.existingSeasons.any((season) {
      final seasonName = season.name.trim().toLowerCase();
      return seasonName == normalizedName && (widget.season == null || season.id != widget.season!.id);
    });

    if (hasDuplicateName) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama musim tanam sudah digunakan. Gunakan nama lain.')),
      );
      return;
    }

    final startDate = DateTime.tryParse(_startDateController.text);
    final endDate = DateTime.tryParse(_endDateController.text);
    if (startDate == null || endDate == null || endDate.isBefore(startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanggal akhir harus setelah tanggal mulai.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final targetKg = double.tryParse(_targetKgController.text) ?? 0;
      Map<String, dynamic> result;

      if (widget.season == null) {
        result = await widget.apiService.createSeason(
          name: _nameController.text,
          startDate: _startDateController.text,
          endDate: _endDateController.text,
          status: _status,
          targetKg: targetKg,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );
      } else {
        result = await widget.apiService.updateSeason(
          widget.season!.id,
          name: _nameController.text,
          startDate: _startDateController.text,
          endDate: _endDateController.text,
          status: _status,
          targetKg: targetKg,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );
      }

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Berhasil disimpan')),
          );
          widget.onSuccess(result['season']);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Gagal disimpan')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  InputDecoration _inputDecoration({required String label, Widget? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: prefixIcon,
      labelStyle: const TextStyle(color: Color(0xFF4A5568)),
      filled: true,
      fillColor: const Color(0xFFFAF9F6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
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
    final isEditMode = widget.season != null;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(4.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditMode ? 'Edit Musim Tanam' : 'Tambah Musim Tanam',
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
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    decoration: _inputDecoration(
                      label: 'Nama Musim Tanam',
                      prefixIcon: const Icon(Icons.calendar_month),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty 
                        ? 'Nama musim tanam wajib diisi' 
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _startDateController,
                    decoration: _inputDecoration(
                      label: 'Tanggal Mulai',
                      prefixIcon: const Icon(Icons.date_range),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(_startDateController),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _endDateController,
                    decoration: _inputDecoration(
                      label: 'Tanggal Selesai',
                      prefixIcon: const Icon(Icons.date_range),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(_endDateController),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _targetKgController,
                    decoration: _inputDecoration(
                      label: 'Target Kg',
                      prefixIcon: const Icon(Icons.scale),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: _inputDecoration(
                      label: 'Status',
                      prefixIcon: const Icon(Icons.info),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('Aktif')),
                      DropdownMenuItem(value: 'completed', child: Text('Selesai')),
                      DropdownMenuItem(value: 'cancelled', child: Text('Dibatalkan')),
                    ],
                    onChanged: (value) => setState(() => _status = value ?? 'active'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    decoration: _inputDecoration(
                      label: 'Catatan (Opsional)',
                      prefixIcon: const Icon(Icons.note),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
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
                          onPressed: _isLoading ? null : _submitForm,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
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
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
