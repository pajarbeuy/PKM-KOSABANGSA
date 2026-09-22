class Sale {
  final int id;
  final int quantity;
  final int pricePerUnit;
  final int totalPrice;
  final String saleDate;
  final String buyerName;
  final String? buyerPhone;
  final String? buyerAddress;
  final String? notes;
  final int? seasonId;
  final String status;
  final String productType;
  final String? productName;

  String get unit => productType == 'processed' ? 'pcs' : 'kg';

  Sale({
    required this.id,
    required this.quantity,
    required this.pricePerUnit,
    required this.totalPrice,
    required this.saleDate,
    required this.buyerName,
    this.buyerPhone,
    this.buyerAddress,
    this.notes,
    this.seasonId,
    required this.status,
    this.productType = 'harvest',
    this.productName,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    final qty = int.tryParse(json['quantity']?.toString() ?? '') ?? 
                double.tryParse(json['weight_kg']?.toString() ?? '')?.round() ?? 0;
                
    final price = int.tryParse(json['price_per_unit']?.toString() ?? '') ?? 
                  double.tryParse(json['price_per_kg']?.toString() ?? '')?.round() ?? 0;
                  
    final total = int.tryParse(json['total_price']?.toString() ?? '') ?? 
                  double.tryParse(json['total']?.toString() ?? '')?.round() ?? 0;
                  
    final date = json['sale_date']?.toString() ?? json['date']?.toString() ?? '1970-01-01';
    
    String statusVal = json['status']?.toString() ?? '';
    if (statusVal.isEmpty) {
      final paymentStatus = json['payment_status']?.toString() ?? '';
      statusVal = (paymentStatus == 'paid') ? 'completed' : 'pending';
    }
    if (statusVal.isEmpty) statusVal = 'completed';

    final pType = json['product_type']?.toString() ?? 'harvest';
    final pName = json['product_name']?.toString() ?? json['processed_product']?['name']?.toString();

    return Sale(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      quantity: qty,
      pricePerUnit: price,
      totalPrice: total,
      saleDate: date.split('T')[0],
      buyerName: json['buyer_name']?.toString() ?? '',
      buyerPhone: json['buyer_phone']?.toString(),
      buyerAddress: json['buyer_address']?.toString(),
      notes: json['notes']?.toString(),
      seasonId: int.tryParse(json['season_id']?.toString() ?? ''),
      status: statusVal,
      productType: pType,
      productName: pName,
    );
  }
}
