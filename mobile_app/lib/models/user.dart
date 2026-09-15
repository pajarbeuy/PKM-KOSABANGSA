class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? farmName;
  final String role;
  final String status;
  final String approval;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.farmName,
    required this.role,
    required this.status,
    required this.approval,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      farmName: json['farm_name']?.toString(),
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
      'role': role,
      'status': status,
      'approval': approval,
    };
  }
}
