class Harvest {
  final int id;
  final int seasonId;
  final String seasonName;
  final int? commodityId;
  final String? commodityName;
  final int quantity;
  final double weightKg;
  final String unit;
  final String harvestDate;
  final String notes;
  final String photo;
  final String status;

  Harvest({
    required this.id,
    required this.seasonId,
    required this.seasonName,
    this.commodityId,
    this.commodityName,
    required this.quantity,
    required this.weightKg,
    this.unit = 'kg',
    required this.harvestDate,
    required this.notes,
    required this.photo,
    required this.status,
  });

  bool get hasPhoto => photo.isNotEmpty;

  factory Harvest.fromJson(Map<String, dynamic> json) {
    return Harvest(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      seasonId: int.tryParse(json['season_id']?.toString() ?? '') ?? 0,
      seasonName: json['season_name'] as String? ?? (json['season'] != null ? json['season']['name'] as String? : null) ?? 'N/A',
      commodityId: int.tryParse(json['commodity_id']?.toString() ?? ''),
      commodityName: json['commodity_name'] as String? ?? (json['commodity'] != null ? json['commodity']['name'] as String? : null),
      quantity: int.tryParse(json['quantity']?.toString() ?? '') ?? 0,
      weightKg: double.tryParse(json['weight_kg']?.toString() ?? '') ?? 0.0,
      unit: json['unit'] as String? ?? 'kg',
      harvestDate: ((json['harvest_date'] ?? json['date']) as String? ?? '1970-01-01').split('T')[0],
      notes: json['notes'] as String? ?? '',
      photo: json['photo'] as String? ?? '',
      status: json['status'] as String? ?? 'recorded',
    );
  }
}
