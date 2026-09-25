double _toDouble(dynamic v, [double defaultValue = 0.0]) {
  if (v == null) return defaultValue;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? defaultValue;
  return defaultValue;
}

int _toInt(dynamic v, [int defaultValue = 0]) {
  if (v == null) return defaultValue;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? defaultValue;
  return defaultValue;
}

class Commission {
  final int id;
  final int saleId;
  final int? orderId;
  final int userId;
  final double rate;
  final double baseAmount;
  final double commissionAmount;
  final double netFarmerAmount;
  final String status;
  final String? notes;
  final String createdAt;
  final String? farmerName;
  final String? productName;
  final String? orderCode;

  Commission({
    required this.id,
    required this.saleId,
    this.orderId,
    required this.userId,
    required this.rate,
    required this.baseAmount,
    required this.commissionAmount,
    required this.netFarmerAmount,
    required this.status,
    this.notes,
    required this.createdAt,
    this.farmerName,
    this.productName,
    this.orderCode,
  });

  factory Commission.fromJson(Map<String, dynamic> json) {
    return Commission(
      id: _toInt(json['id']),
      saleId: _toInt(json['sale_id']),
      orderId: json['order_id'] != null ? _toInt(json['order_id']) : null,
      userId: _toInt(json['user_id']),
      rate: _toDouble(json['rate'], 10.0),
      baseAmount: _toDouble(json['base_amount']),
      commissionAmount: _toDouble(json['commission_amount']),
      netFarmerAmount: _toDouble(json['net_farmer_amount']),
      status: json['status'] as String? ?? 'calculated',
      notes: json['notes'] as String?,
      createdAt: json['created_at']?.toString() ?? '',
      farmerName: json['farmer']?['name'] as String?,
      productName: json['sale']?['processed_product']?['name'] as String?,
      orderCode: json['order']?['order_code'] as String?,
    );
  }
}

class CommissionSummary {
  final int totalTransactions;
  final double totalGrossAmount;
  final double totalCommissionAmount;
  final double totalNetFarmerAmount;
  final double commissionRateDefault;

  CommissionSummary({
    required this.totalTransactions,
    required this.totalGrossAmount,
    required this.totalCommissionAmount,
    required this.totalNetFarmerAmount,
    required this.commissionRateDefault,
  });

  factory CommissionSummary.fromJson(Map<String, dynamic> json) {
    return CommissionSummary(
      totalTransactions: _toInt(json['total_transactions'] ?? json['total_sales_count']),
      totalGrossAmount: _toDouble(json['total_gross_amount'] ?? json['total_gross_sales']),
      totalCommissionAmount: _toDouble(json['total_commission_amount'] ?? json['total_platform_commission']),
      totalNetFarmerAmount: _toDouble(json['total_net_farmer_amount'] ?? json['total_net_received']),
      commissionRateDefault: _toDouble(json['commission_rate_default'], 10.0),
    );
  }
}
