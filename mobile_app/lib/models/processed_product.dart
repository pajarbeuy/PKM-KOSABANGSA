class ProcessedProduct {
  final int id;
  final int ownerId;
  final String ownerName;
  final String? farmName;
  final String name;
  final double price;
  final int stock;
  final String? description;
  final String? photo;
  final String? photoUrl;
  final String status;
  final String? createdAt;
  final String? updatedAt;

  ProcessedProduct({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    this.farmName,
    required this.name,
    required this.price,
    required this.stock,
    this.description,
    this.photo,
    this.photoUrl,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  bool get isActive => status == 'active';
  bool get isOutOfStock => status == 'out_of_stock' || stock <= 0;
  bool get isInactive => status == 'inactive';

  factory ProcessedProduct.fromJson(Map<String, dynamic> json) {
    final parsedStock = int.tryParse(json['stock']?.toString() ?? '') ?? 0;
    String statusVal = json['status']?.toString() ?? '';
    if (statusVal.isEmpty) {
      statusVal = parsedStock > 0 ? 'active' : 'out_of_stock';
    }

    return ProcessedProduct(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      ownerId: int.tryParse(json['owner_id']?.toString() ?? '') ?? 0,
      ownerName: json['owner_name']?.toString() ?? 'Petani',
      farmName: json['farm_name']?.toString(),
      name: json['name']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '') ?? 0.0,
      stock: parsedStock,
      description: json['description']?.toString(),
      photo: json['photo']?.toString(),
      photoUrl: json['photo_url']?.toString(),
      status: statusVal,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'price': price,
      'stock': stock,
      'description': description,
      'photo': photo,
      'status': status,
    };
  }
}
