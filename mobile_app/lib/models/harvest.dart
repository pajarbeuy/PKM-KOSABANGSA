class Harvest {
  final int id;
  final int seasonId;
  final String seasonName;
  final int? commodityId;
  final String? commodityName;
  final int? marketPriceId;
  final double? marketPriceSnapshot;
  final String? marketPriceEffectiveDate;
  final double? grossHarvestValue;
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
    this.marketPriceId,
    this.marketPriceSnapshot,
    this.marketPriceEffectiveDate,
    this.grossHarvestValue,
    required this.quantity,
    required this.weightKg,
    this.unit = 'kg',
    required this.harvestDate,
    required this.notes,
    required this.photo,
    required this.status,
  });

  bool get hasPhoto => photo.isNotEmpty;
  bool get hasMarketPriceSnapshot => marketPriceSnapshot != null && marketPriceSnapshot! > 0;

  /// Hitung Gross Harvest Value (Estimasi Pendapatan Kotor Panen)
  double get calculatedGrossValue {
    if (grossHarvestValue != null) return grossHarvestValue!;
    if (marketPriceSnapshot != null) return weightKg * marketPriceSnapshot!;
    return 0.0;
  }

  factory Harvest.fromJson(Map<String, dynamic> json) {
    final snapshot = double.tryParse(json['market_price_snapshot']?.toString() ?? '');
    final weight = double.tryParse(json['weight_kg']?.toString() ?? '') ?? 0.0;
    final gross = double.tryParse(json['gross_harvest_value']?.toString() ?? '') ?? (snapshot != null ? weight * snapshot : null);

    return Harvest(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      seasonId: int.tryParse(json['season_id']?.toString() ?? '') ?? 0,
      seasonName: json['season_name'] as String? ?? (json['season'] != null ? json['season']['name'] as String? : null) ?? 'N/A',
      commodityId: int.tryParse(json['commodity_id']?.toString() ?? ''),
      commodityName: json['commodity_name'] as String? ?? (json['commodity'] != null ? json['commodity']['name'] as String? : null),
      marketPriceId: int.tryParse(json['market_price_id']?.toString() ?? ''),
      marketPriceSnapshot: snapshot,
      marketPriceEffectiveDate: json['market_price_effective_date'] != null ? (json['market_price_effective_date'] as String).split('T')[0] : null,
      grossHarvestValue: gross,
      quantity: int.tryParse(json['quantity']?.toString() ?? '') ?? 0,
      weightKg: weight,
      unit: json['unit'] as String? ?? 'kg',
      harvestDate: ((json['harvest_date'] ?? json['date']) as String? ?? '1970-01-01').split('T')[0],
      notes: json['notes'] as String? ?? '',
      photo: json['photo'] as String? ?? '',
      status: json['status'] as String? ?? 'recorded',
    );
  }
}
