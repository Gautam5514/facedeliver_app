/// Roles the backend issues in the signed token payload.
enum UserRole { guest, admin, superadmin, unknown }

UserRole roleFromString(String? value) => switch (value) {
      'user' => UserRole.guest,
      'admin' => UserRole.admin,
      'superadmin' => UserRole.superadmin,
      _ => UserRole.unknown,
    };

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.profileImageUrl,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? profileImageUrl;

  bool get isAdmin => role == UserRole.admin;
  bool get isGuest => role == UserRole.guest;

  String get initial =>
      name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final image = (json['profileImageUrl'] as String?)?.trim();
    return AppUser(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? (json['name'] as String).trim()
          : 'Guest',
      email: (json['email'] as String? ?? '').trim(),
      role: roleFromString(json['role'] as String?),
      profileImageUrl: image?.isNotEmpty == true ? image : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': switch (role) {
          UserRole.guest => 'user',
          UserRole.admin => 'admin',
          UserRole.superadmin => 'superadmin',
          UserRole.unknown => 'user',
        },
        'profileImageUrl': profileImageUrl ?? '',
      };

  AppUser copyWith({String? name, String? profileImageUrl}) => AppUser(
        id: id,
        name: name ?? this.name,
        email: email,
        role: role,
        profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      );
}
