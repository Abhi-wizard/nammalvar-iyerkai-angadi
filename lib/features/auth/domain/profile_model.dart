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

  static String normalizeDisplayName(String? name, String? email) {
    if (email != null && email.toLowerCase().contains('stdharan73')) {
      return 'Tharanidharan';
    }
    if (name != null) {
      final trimmed = name.trim();
      if (trimmed.toLowerCase().contains('stdharan73')) {
        return 'Tharanidharan';
      }
      if (trimmed.isNotEmpty && trimmed.toLowerCase() != 'user' && trimmed.toLowerCase() != 'seller') {
        return trimmed;
      }
    }
    if (email != null && email.contains('@')) {
      final local = email.split('@')[0];
      if (local.toLowerCase() == 'stdharan73') return 'Tharanidharan';
      return local;
    }
    return name ?? 'User';
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final email = json['email'] as String?;
    final rawName = json['name'] as String?;
    return ProfileModel(
      id: json['id'] as String,
      name: normalizeDisplayName(rawName, email),
      phone: json['phone'] as String?,
      email: email,
      role: (json['role'] as String? ?? 'seller').toLowerCase() == 'admin'
          ? UserRole.admin
          : UserRole.seller,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toLocal()
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
