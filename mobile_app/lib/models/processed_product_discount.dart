class ProcessedProductDiscount {
  final int id;
  final int processedProductId;
  final String productName;
  final double originalPrice;
  final double discountPercentage;
  final String startDate;
  final String endDate;
  final int createdBy;
  final String? creatorName;
  final String? createdAt;

  ProcessedProductDiscount({
    required this.id,
    required this.processedProductId,
    required this.productName,
    required this.originalPrice,
    required this.discountPercentage,
    required this.startDate,
    required this.endDate,
    required this.createdBy,
    this.creatorName,
    this.createdAt,
  });

  double get discountAmount => (originalPrice * (discountPercentage / 100));
  double get effectivePrice => originalPrice - discountAmount;

  bool get isActive {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    try {
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);
      return (today.isAfter(start) || today.isAtSameMomentAs(start)) &&
             (today.isBefore(end) || today.isAtSameMomentAs(end));
    } catch (_) {
      return false;
    }
  }

  bool get isUpcoming {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    try {
      final start = DateTime.parse(startDate);
      return today.isBefore(start);
    } catch (_) {
      return false;
    }
  }

  bool get isExpired {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    try {
      final end = DateTime.parse(endDate);
      return today.isAfter(end);
    } catch (_) {
      return false;
    }
  }

  String get statusLabel {
    if (isActive) return 'Aktif';
    if (isUpcoming) return 'Akan Datang';
    return 'Berakhir';
  }

  factory ProcessedProductDiscount.fromJson(Map<String, dynamic> json) {
    final prod = json['processed_product'] as Map<String, dynamic>?;
    final creator = json['creator'] as Map<String, dynamic>?;

    return ProcessedProductDiscount(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      processedProductId: int.tryParse(json['processed_product_id']?.toString() ?? '') ?? 0,
      productName: prod?['name']?.toString() ?? json['product_name']?.toString() ?? 'Produk Olahan',
      originalPrice: double.tryParse(prod?['price']?.toString() ?? json['original_price']?.toString() ?? '') ?? 0.0,
      discountPercentage: double.tryParse(json['discount_percentage']?.toString() ?? '') ?? 0.0,
      startDate: json['start_date']?.toString().split('T')[0] ?? '',
      endDate: json['end_date']?.toString().split('T')[0] ?? '',
      createdBy: int.tryParse(json['created_by']?.toString() ?? '') ?? 0,
      creatorName: creator?['name']?.toString() ?? json['creator_name']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'processed_product_id': processedProductId,
      'discount_percentage': discountPercentage,
      'start_date': startDate,
      'end_date': endDate,
    };
  }
}
