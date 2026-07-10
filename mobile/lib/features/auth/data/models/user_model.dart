class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.ownerId,
    this.emailVerified = true,
  });

  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String? ownerId;
  final bool emailVerified;

  bool get isOwner => ownerId == null && role == 'owner';

  String get displayName {
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? email : name;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      role: json['role'] as String? ?? 'owner',
      ownerId: json['ownerId'] as String?,
      emailVerified: json['emailVerified'] as bool? ?? true,
    );
  }
}
