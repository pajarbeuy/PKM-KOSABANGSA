class Cost {
  final int id;
  final int? seasonId;
  final String seasonName;
  final String category;
  final double amount;
  final String date;
  final String notes;

  Cost({
    required this.id,
    this.seasonId,
    required this.seasonName,
    required this.category,
    required this.amount,
    required this.date,
    required this.notes,
  });

  factory Cost.fromJson(Map<String, dynamic> json) {
    String name = 'N/A';
    if (json['season'] != null && json['season'] is Map) {
      name = json['season']['name']?.toString() ?? 'N/A';
    } else if (json['season_name'] != null) {
      name = json['season_name']?.toString() ?? 'N/A';
    }
    
    return Cost(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      seasonId: int.tryParse(json['season_id']?.toString() ?? ''),
      seasonName: name,
      category: json['category']?.toString() ?? 'other',
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0.0,
      date: json['date']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
    );
  }
}
