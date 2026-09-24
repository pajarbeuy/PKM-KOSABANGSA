class FarmerGroup {
  final int id;
  final String name;
  final String code;
  final String status;
  final String? leaderName;
  final String? village;
  final String? description;
  final int membersCount;

  FarmerGroup({
    required this.id,
    required this.name,
    required this.code,
    required this.status,
    this.leaderName,
    this.village,
    this.description,
    this.membersCount = 0,
  });

  factory FarmerGroup.fromJson(Map<String, dynamic> json) {
    return FarmerGroup(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active',
      leaderName: json['leader_name']?.toString(),
      village: json['village']?.toString(),
      description: json['description']?.toString(),
      membersCount: json['members_count'] is int
          ? json['members_count']
          : int.tryParse(json['members_count']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'status': status,
    'leader_name': leaderName,
    'village': village,
    'description': description,
    'members_count': membersCount,
  };
}
