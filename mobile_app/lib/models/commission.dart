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
      id: json['id'] as int,
      saleId: json['sale_id'] as int,
      orderId: json['order_id'] as int?,
      userId: json['user_id'] as int,
      rate: (json['rate'] as num?)?.toDouble() ?? 10.0,
      baseAmount: (json['base_amount'] as num?)?.toDouble() ?? 0.0,
      commissionAmount: (json['commission_amount'] as num?)?.toDouble() ?? 0.0,
      netFarmerAmount: (json['net_farmer_amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'calculated',
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String? ?? '',
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
      totalTransactions: (json['total_transactions'] ?? json['total_sales_count'] ?? 0) as int,
      totalGrossAmount: ((json['total_gross_amount'] ?? json['total_gross_sales'] ?? 0) as num).toDouble(),
      totalCommissionAmount: ((json['total_commission_amount'] ?? json['total_platform_commission'] ?? 0) as num).toDouble(),
      totalNetFarmerAmount: ((json['total_net_farmer_amount'] ?? json['total_net_received'] ?? 0) as num).toDouble(),
      commissionRateDefault: (json['commission_rate_default'] as num?)?.toDouble() ?? 10.0,
    );
  }
}
