class FarmerCommodity {
  final int id;
  final int userId;
  final String name;
  final String? code;
  final String unit;
  final String? description;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? farmer;

  FarmerCommodity({
    required this.id,
    required this.userId,
    required this.name,
    this.code,
    required this.unit,
    this.description,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.farmer,
  });

  bool get isActive => status == 'active';

  factory FarmerCommodity.fromJson(Map<String, dynamic> json) {
    return FarmerCommodity(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString(),
      unit: json['unit']?.toString() ?? 'kg',
      description: json['description']?.toString(),
      status: json['status']?.toString() ?? 'active',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      farmer: json['farmer'] is Map<String, dynamic> ? json['farmer'] as Map<String, dynamic> : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'code': code,
    'unit': unit,
    'description': description,
    'status': status,
  };
}
