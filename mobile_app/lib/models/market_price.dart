class MarketPrice {
  final int id;
  final int commodityId;
  final String commodityName;
  final double price;
  final String unit;
  final String effectiveDate;
  final String source;
  final String notes;
  final bool isReferenced;
  final DateTime? createdAt;

  MarketPrice({
    required this.id,
    required this.commodityId,
    required this.commodityName,
    required this.price,
    this.unit = 'kg',
    required this.effectiveDate,
    this.source = 'manual',
    this.notes = '',
    this.isReferenced = false,
    this.createdAt,
  });

  factory MarketPrice.fromJson(Map<String, dynamic> json) {
    return MarketPrice(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      commodityId: int.tryParse(json['commodity_id']?.toString() ?? '') ?? 0,
      commodityName: json['commodity_name'] as String? ?? 'N/A',
      price: double.tryParse(json['price']?.toString() ?? '') ?? 0.0,
      unit: json['unit'] as String? ?? 'kg',
      effectiveDate: (json['effective_date'] as String? ?? '').split('T')[0],
      source: json['source'] as String? ?? 'manual',
      notes: json['notes'] as String? ?? '',
      isReferenced: json['is_referenced'] == true,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'commodity_id': commodityId,
      'price': price,
      'unit': unit,
      'effective_date': effectiveDate,
      'source': source,
      'notes': notes,
    };
  }
}
