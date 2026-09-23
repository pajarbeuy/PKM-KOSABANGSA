class DashboardData {
  final int totalStok;
  final int totalPanen;
  final int totalPenjualan;
  final int totalBiaya;
  final int targetPanen;
  final int minStock;
  final int maxStock;
  final bool notifyLowStock;
  final bool notifyNewSale;
  final bool notifyCost;
  final double totalRawSalesKg;
  final double totalRawSalesRp;
  final double totalProcessedSalesPcs;
  final double totalProcessedSalesRp;
  final List<HarvestSummary> harvests;
  final List<TransactionSummary> transactions;
  final ProfitLoss profitLoss;
  final List<MonthlyStat> monthlyStats;

  DashboardData({
    required this.totalStok,
    required this.totalPanen,
    required this.totalPenjualan,
    required this.totalBiaya,
    required this.targetPanen,
    required this.minStock,
    required this.maxStock,
    required this.notifyLowStock,
    required this.notifyNewSale,
    required this.notifyCost,
    this.totalRawSalesKg = 0.0,
    this.totalRawSalesRp = 0.0,
    this.totalProcessedSalesPcs = 0.0,
    this.totalProcessedSalesRp = 0.0,
    required this.harvests,
    required this.transactions,
    required this.profitLoss,
    required this.monthlyStats,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      totalStok: int.tryParse(json['totalStok']?.toString() ?? '') ?? 0,
      totalPanen: int.tryParse(json['totalPanen']?.toString() ?? '') ?? 0,
      totalPenjualan: int.tryParse(json['totalPenjualan']?.toString() ?? '') ?? 0,
      totalBiaya: int.tryParse(json['totalBiaya']?.toString() ?? '') ?? 0,
      targetPanen: int.tryParse(json['targetPanen']?.toString() ?? '') ?? 0,
      minStock: int.tryParse(json['minStock']?.toString() ?? '') ?? 100,
      maxStock: int.tryParse(json['maxStock']?.toString() ?? '') ?? 5000,
      notifyLowStock: json['notifyLowStock'] == null ? true : (json['notifyLowStock'] == true || json['notifyLowStock'].toString() == '1'),
      notifyNewSale: json['notifyNewSale'] == null ? true : (json['notifyNewSale'] == true || json['notifyNewSale'].toString() == '1'),
      notifyCost: json['notifyCost'] == null ? true : (json['notifyCost'] == true || json['notifyCost'].toString() == '1'),
      totalRawSalesKg: double.tryParse(json['totalRawSalesKg']?.toString() ?? '') ?? 0.0,
      totalRawSalesRp: double.tryParse(json['totalRawSalesRp']?.toString() ?? '') ?? 0.0,
      totalProcessedSalesPcs: double.tryParse(json['totalProcessedSalesPcs']?.toString() ?? '') ?? 0.0,
      totalProcessedSalesRp: double.tryParse(json['totalProcessedSalesRp']?.toString() ?? '') ?? 0.0,
      harvests: (json['harvests'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((e) => HarvestSummary.fromJson(e))
              .toList() ??
          [],
      transactions: (json['transactions'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((e) => TransactionSummary.fromJson(e))
              .toList() ??
          [],
      profitLoss: ProfitLoss.fromJson(
          json['profitLoss'] is Map<String, dynamic> ? json['profitLoss'] as Map<String, dynamic> : {}),
      monthlyStats: (json['monthlyStats'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((e) => MonthlyStat.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class MonthlyStat {
  final String label;
  final double harvest;
  final double sales;
  final double salesHarvest;
  final double salesProcessed;
  final String salesUnit;
  final double harvestKg;
  final double harvestSalesKg;
  final double harvestSalesRp;
  final double processedSalesPcs;
  final double processedSalesRp;

  MonthlyStat({
    required this.label,
    required this.harvest,
    required this.sales,
    this.salesHarvest = 0.0,
    this.salesProcessed = 0.0,
    this.salesUnit = 'kg',
    double? harvestKg,
    double? harvestSalesKg,
    this.harvestSalesRp = 0.0,
    double? processedSalesPcs,
    this.processedSalesRp = 0.0,
  })  : harvestKg = harvestKg ?? harvest,
        harvestSalesKg = harvestSalesKg ?? salesHarvest,
        processedSalesPcs = processedSalesPcs ?? salesProcessed;

  factory MonthlyStat.fromJson(Map<String, dynamic> json) {
    final rawHarvest = double.tryParse(json['harvest_kg']?.toString() ?? json['harvest']?.toString() ?? '') ?? 0.0;
    final sHarvest = double.tryParse(json['harvest_sales_kg']?.toString() ?? json['sales_harvest']?.toString() ?? '') ?? 0.0;
    final sProc = double.tryParse(json['processed_sales_pcs']?.toString() ?? json['sales_processed']?.toString() ?? '') ?? 0.0;
    final hRp = double.tryParse(json['harvest_sales_rp']?.toString() ?? '') ?? 0.0;
    final pRp = double.tryParse(json['processed_sales_rp']?.toString() ?? '') ?? 0.0;
    final unit = json['sales_unit']?.toString() ?? (sProc > 0 && sHarvest == 0 ? 'pcs' : 'kg');

    return MonthlyStat(
      label: json['label']?.toString() ?? '',
      harvest: rawHarvest,
      sales: sHarvest > 0 ? sHarvest : (double.tryParse(json['sales']?.toString() ?? '') ?? 0.0),
      salesHarvest: sHarvest,
      salesProcessed: sProc,
      salesUnit: unit,
      harvestKg: rawHarvest,
      harvestSalesKg: sHarvest,
      harvestSalesRp: hRp,
      processedSalesPcs: sProc,
      processedSalesRp: pRp,
    );
  }
}

class HarvestSummary {
  final int id;
  final String seasonName;
  final int quantity;
  final String status;

  HarvestSummary({
    required this.id,
    required this.seasonName,
    required this.quantity,
    required this.status,
  });

  factory HarvestSummary.fromJson(Map<String, dynamic> json) {
    return HarvestSummary(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      seasonName: json['season_name']?.toString() ?? (json['season'] is Map ? json['season']['name']?.toString() : null) ?? 'N/A',
      quantity: int.tryParse(json['quantity']?.toString() ?? '') ?? 0,
      status: json['status']?.toString() ?? 'pending',
    );
  }
}

class TransactionSummary {
  final int id;
  final String type;
  final int quantity;
  final String createdAt;

  TransactionSummary({
    required this.id,
    required this.type,
    required this.quantity,
    required this.createdAt,
  });

  factory TransactionSummary.fromJson(Map<String, dynamic> json) {
    return TransactionSummary(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      type: json['type']?.toString() ?? 'unknown',
      quantity: int.tryParse(json['quantity']?.toString() ?? '') ?? 0,
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class ProfitLoss {
  final int revenue;
  final int cost;
  final int profit;

  ProfitLoss({
    required this.revenue,
    required this.cost,
    required this.profit,
  });

  factory ProfitLoss.fromJson(Map<String, dynamic> json) {
    return ProfitLoss(
      revenue: int.tryParse(json['revenue']?.toString() ?? '') ?? double.tryParse(json['revenue']?.toString() ?? '')?.round() ?? 0,
      cost: int.tryParse(json['cost']?.toString() ?? '') ?? double.tryParse(json['cost']?.toString() ?? '')?.round() ?? 0,
      profit: int.tryParse(json['profit']?.toString() ?? '') ?? double.tryParse(json['profit']?.toString() ?? '')?.round() ?? 0,
    );
  }
}
