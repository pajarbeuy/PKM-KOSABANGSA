class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? farmName;
  final int? farmerGroupId;
  final String? farmerGroupName;
  final String? farmerGroupCode;
  final String role;
  final String status;
  final String approval;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.farmName,
    this.farmerGroupId,
    this.farmerGroupName,
    this.farmerGroupCode,
    required this.role,
    required this.status,
    required this.approval,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    int? fgId;
    if (json['farmer_group_id'] != null) {
      fgId = int.tryParse(json['farmer_group_id'].toString());
    }

    String? fgName;
    String? fgCode;
    if (json['farmer_group'] is Map) {
      fgName = json['farmer_group']['name']?.toString();
      fgCode = json['farmer_group']['code']?.toString();
      fgId ??= int.tryParse(json['farmer_group']['id']?.toString() ?? '');
    }

    return User(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      farmName: json['farm_name']?.toString(),
      farmerGroupId: fgId,
      farmerGroupName: fgName,
      farmerGroupCode: fgCode,
      role: json['role']?.toString() ?? 'user',
      status: json['status']?.toString() ?? 'active',
      approval: json['approval']?.toString() ?? 'approved',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'farm_name': farmName,
      'farmer_group_id': farmerGroupId,
      'farmer_group_name': farmerGroupName,
      'farmer_group_code': farmerGroupCode,
      'role': role,
      'status': status,
      'approval': approval,
    };
  }
}
