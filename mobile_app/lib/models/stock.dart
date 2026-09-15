class StockTransaction {
  final int id;
  final String type;
  final int quantity;
  final String transactionDate;
  final String? notes;
  final String? reference;
  final String createdAt;

  StockTransaction({
    required this.id,
    required this.type,
    required this.quantity,
    required this.transactionDate,
    this.notes,
    this.reference,
    required this.createdAt,
  });

  factory StockTransaction.fromJson(Map<String, dynamic> json) {
    return StockTransaction(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      type: json['type']?.toString() ?? 'unknown',
      quantity: int.tryParse(json['quantity']?.toString() ?? '') ?? 0,
      transactionDate: json['transaction_date']?.toString() ?? '',
      notes: json['notes']?.toString(),
      reference: json['reference']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class StockData {
  final int totalIncoming;
  final int totalOutgoing;
  final int currentStock;
  final List<StockTransaction> transactions;

  StockData({
    required this.totalIncoming,
    required this.totalOutgoing,
    required this.currentStock,
    required this.transactions,
  });

  factory StockData.fromJson(Map<String, dynamic> json) {
    return StockData(
      totalIncoming: int.tryParse(json['totalIncoming']?.toString() ?? json['total_incoming']?.toString() ?? '') ?? 0,
      totalOutgoing: int.tryParse(json['totalOutgoing']?.toString() ?? json['total_outgoing']?.toString() ?? '') ?? 0,
      currentStock: int.tryParse(json['currentStock']?.toString() ?? json['current_stock']?.toString() ?? '') ?? 0,
      transactions: (json['transactions'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((e) => StockTransaction.fromJson(e))
              .toList() ??
          [],
    );
  }
}
