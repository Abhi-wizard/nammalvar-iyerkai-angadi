enum UserRole { admin, seller }

class ProfileModel {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;

  ProfileModel({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    required this.role,
    this.isActive = true,
    required this.createdAt,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isSeller => role == UserRole.seller;

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'User',
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      role: (json['role'] as String? ?? 'seller').toLowerCase() == 'admin'
          ? UserRole.admin
          : UserRole.seller,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'role': role == UserRole.admin ? 'admin' : 'seller',
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ProfileModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    UserRole? role,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
