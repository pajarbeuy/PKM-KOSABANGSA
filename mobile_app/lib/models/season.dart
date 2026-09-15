class Season {
  final int id;
  final String name;
  final String startDate;
  final String endDate;
  final String status;
  final String? notes;
  final double targetKg;
  final double totalPanen;

  Season({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.notes,
    this.targetKg = 0,
    this.totalPanen = 0,
  });

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      startDate: (json['start_date']?.toString() ?? '').split('T')[0],
      endDate: (json['end_date']?.toString() ?? '').split('T')[0],
      status: json['status']?.toString() ?? 'active',
      notes: json['notes']?.toString(),
      targetKg: double.tryParse(json['target_kg']?.toString() ?? '') ?? 0.0,
      totalPanen: double.tryParse(json['total_harvest_kg']?.toString() ?? '') ?? 0.0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Season && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
