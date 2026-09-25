/// Model hasil ekonomi per panen (Phase 6)
class HarvestEconomicResult {
  final int harvestId;
  final String? harvestDate;
  final int? seasonId;
  final String? seasonName;
  final int? commodityId;
  final String? commodityName;
  final double weightKg;
  final double quantity;
  final String unit;
  final double? marketPriceSnapshot;
  final String? marketPriceEffectiveDate;
  final double? revenue;
  final double? allocatedProductionCost;
  final double? profitLoss;
  final String? profitLossStatus; // 'profit' | 'loss' | null

  HarvestEconomicResult({
    required this.harvestId,
    this.harvestDate,
    this.seasonId,
    this.seasonName,
    this.commodityId,
    this.commodityName,
    required this.weightKg,
    required this.quantity,
    this.unit = 'kg',
    this.marketPriceSnapshot,
    this.marketPriceEffectiveDate,
    this.revenue,
    this.allocatedProductionCost,
    this.profitLoss,
    this.profitLossStatus,
  });

  double? get grossHarvestValue => revenue;
  bool get isProfit => profitLossStatus == 'profit';
  bool get isLoss   => profitLossStatus == 'loss';
  bool get hasEconomicData => revenue != null && profitLoss != null;

  factory HarvestEconomicResult.fromJson(Map<String, dynamic> json) {
    final rev = double.tryParse(json['revenue']?.toString() ?? '') ??
        double.tryParse(json['gross_harvest_value']?.toString() ?? '');

    return HarvestEconomicResult(
      harvestId:                int.tryParse(json['harvest_id']?.toString() ?? '') ?? 0,
      harvestDate:              json['harvest_date'] as String?,
      seasonId:                 int.tryParse(json['season_id']?.toString() ?? ''),
      seasonName:               json['season_name'] as String?,
      commodityId:              int.tryParse(json['commodity_id']?.toString() ?? ''),
      commodityName:            json['commodity_name'] as String?,
      weightKg:                 double.tryParse(json['weight_kg']?.toString() ?? '') ?? 0.0,
      quantity:                 double.tryParse(json['quantity']?.toString() ?? '') ?? 0.0,
      unit:                     json['unit'] as String? ?? 'kg',
      marketPriceSnapshot:      double.tryParse(json['market_price_snapshot']?.toString() ?? ''),
      marketPriceEffectiveDate: json['market_price_effective_date'] as String?,
      revenue:                  rev,
      allocatedProductionCost:  double.tryParse(json['allocated_production_cost']?.toString() ?? ''),
      profitLoss:               double.tryParse(json['profit_loss']?.toString() ?? ''),
      profitLossStatus:         json['profit_loss_status'] as String?,
    );
  }
}

/// Ringkasan ekonomi per musim tanam
class SeasonEconomicSummary {
  final int seasonId;
  final String seasonName;
  final String? seasonStart;
  final String? seasonEnd;
  final int? commodityId;
  final String? commodityName;
  final double totalWeightKg;
  final int harvestCount;
  final double? seasonRevenue;
  final double seasonProductionCost;
  final double? seasonProfitLoss;
  final String? profitLossStatus;
  final bool hasCompletePriceData;
  final List<HarvestEconomicResult> harvests;

  SeasonEconomicSummary({
    required this.seasonId,
    required this.seasonName,
    this.seasonStart,
    this.seasonEnd,
    this.commodityId,
    this.commodityName,
    required this.totalWeightKg,
    required this.harvestCount,
    this.seasonRevenue,
    required this.seasonProductionCost,
    this.seasonProfitLoss,
    this.profitLossStatus,
    required this.hasCompletePriceData,
    required this.harvests,
  });

  double? get totalGrossHarvestValue => seasonRevenue;
  double get totalProductionCost => seasonProductionCost;
  double? get totalProfitLoss => seasonProfitLoss;
  bool get isProfit => profitLossStatus == 'profit';
  bool get isLoss   => profitLossStatus == 'loss';

  factory SeasonEconomicSummary.fromJson(Map<String, dynamic> json) {
    final harvestsList = (json['harvests'] as List<dynamic>? ?? [])
        .map((h) => HarvestEconomicResult.fromJson(h as Map<String, dynamic>))
        .toList();

    final rev = double.tryParse(json['season_revenue']?.toString() ?? '') ??
        double.tryParse(json['total_gross_harvest_value']?.toString() ?? '');
    final cost = double.tryParse(json['season_production_cost']?.toString() ?? '') ??
        double.tryParse(json['total_production_cost']?.toString() ?? '') ?? 0.0;
    final pl = double.tryParse(json['season_profit_loss']?.toString() ?? '') ??
        double.tryParse(json['total_profit_loss']?.toString() ?? '');

    return SeasonEconomicSummary(
      seasonId:               int.tryParse(json['season_id']?.toString() ?? '') ?? 0,
      seasonName:             json['season_name'] as String? ?? 'N/A',
      seasonStart:            json['season_start'] as String?,
      seasonEnd:              json['season_end'] as String?,
      commodityId:            int.tryParse(json['commodity_id']?.toString() ?? ''),
      commodityName:          json['commodity_name'] as String?,
      totalWeightKg:          double.tryParse(json['total_weight_kg']?.toString() ?? '') ?? 0.0,
      harvestCount:           int.tryParse(json['harvest_count']?.toString() ?? '') ?? 0,
      seasonRevenue:          rev,
      seasonProductionCost:   cost,
      seasonProfitLoss:       pl,
      profitLossStatus:       json['profit_loss_status'] as String?,
      hasCompletePriceData:   json['has_complete_price_data'] as bool? ?? false,
      harvests:               harvestsList,
    );
  }
}

/// Ringkasan ekonomi keseluruhan petani (semua musim)
class FarmerEconomicSummary {
  final double totalWeightKg;
  final double? revenue;
  final double totalProductionCost;
  final double? totalProfitLoss;
  final String? profitLossStatus;
  final int seasonCount;
  final List<SeasonEconomicSummary> seasons;

  FarmerEconomicSummary({
    required this.totalWeightKg,
    this.revenue,
    required this.totalProductionCost,
    this.totalProfitLoss,
    this.profitLossStatus,
    required this.seasonCount,
    required this.seasons,
  });

  double? get totalGrossHarvestValue => revenue;
  bool get isProfit => profitLossStatus == 'profit';
  bool get isLoss   => profitLossStatus == 'loss';

  factory FarmerEconomicSummary.fromJson(Map<String, dynamic> json) {
    final seasonsList = (json['seasons'] as List<dynamic>? ?? [])
        .map((s) => SeasonEconomicSummary.fromJson(s as Map<String, dynamic>))
        .toList();

    final rev = double.tryParse(json['revenue']?.toString() ?? '') ??
        double.tryParse(json['total_gross_harvest_value']?.toString() ?? '');

    return FarmerEconomicSummary(
      totalWeightKg:          double.tryParse(json['total_weight_kg']?.toString() ?? '') ?? 0.0,
      revenue:                rev,
      totalProductionCost:    double.tryParse(json['total_production_cost']?.toString() ?? '') ?? 0.0,
      totalProfitLoss:        double.tryParse(json['total_profit_loss']?.toString() ?? ''),
      profitLossStatus:       json['profit_loss_status'] as String?,
      seasonCount:            int.tryParse(json['season_count']?.toString() ?? '') ?? 0,
      seasons:                seasonsList,
    );
  }
}
