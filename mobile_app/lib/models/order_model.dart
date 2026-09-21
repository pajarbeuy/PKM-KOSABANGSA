class OrderItemModel {
  final int id;
  final int processedProductId;
  final String productName;
  final String? productPhotoUrl;
  final String? ownerName;
  final int quantity;
  final double priceSnapshot;
  final double subtotal;

  OrderItemModel({
    required this.id,
    required this.processedProductId,
    required this.productName,
    this.productPhotoUrl,
    this.ownerName,
    required this.quantity,
    required this.priceSnapshot,
    required this.subtotal,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      processedProductId: int.tryParse(json['processed_product_id']?.toString() ?? '') ?? 0,
      productName: json['product_name']?.toString() ?? 'Produk Olahan',
      productPhotoUrl: json['product_photo_url']?.toString(),
      ownerName: json['owner_name']?.toString() ?? 'Petani',
      quantity: int.tryParse(json['quantity']?.toString() ?? '') ?? 1,
      priceSnapshot: double.tryParse(json['price_snapshot']?.toString() ?? '') ?? 0.0,
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '') ?? 0.0,
    );
  }
}

class OrderModel {
  final int id;
  final String orderCode;
  final String customerName;
  final String customerPhone;
  final String? customerAddress;
  final String status;
  final double totalAmount;
  final String? notes;
  final bool hasSale;
  final int? saleId;
  final String? createdAt;
  final String? updatedAt;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.orderCode,
    required this.customerName,
    required this.customerPhone,
    this.customerAddress,
    required this.status,
    required this.totalAmount,
    this.notes,
    this.hasSale = false,
    this.saleId,
    this.createdAt,
    this.updatedAt,
    this.items = const [],
  });

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isProcessing => status == 'processing';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'];
    List<OrderItemModel> parsedItems = [];
    if (rawItems is List) {
      parsedItems = rawItems
          .map((i) => OrderItemModel.fromJson(i as Map<String, dynamic>))
          .toList();
    }

    return OrderModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      orderCode: json['order_code']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? '',
      customerPhone: json['customer_phone']?.toString() ?? '',
      customerAddress: json['customer_address']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '') ?? 0.0,
      notes: json['notes']?.toString(),
      hasSale: json['has_sale'] == true,
      saleId: int.tryParse(json['sale_id']?.toString() ?? ''),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      items: parsedItems,
    );
  }
}
