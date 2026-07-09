import 'package:purchase_journal/core/constants/api_constants.dart';
import 'package:purchase_journal/core/network/api_client.dart';

class MemberModel {
  const MemberModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.ownerId,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String? ownerId;
  final String createdAt;

  String get displayName {
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? email : name;
  }

  factory MemberModel.fromJson(Map<String, dynamic> json) => MemberModel(
        id: json['id'] as String,
        email: json['email'] as String,
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        role: json['role'] as String? ?? 'member',
        ownerId: json['ownerId'] as String?,
        createdAt: json['createdAt']?.toString() ?? '',
      );
}

class MemberRemoteDataSource {
  MemberRemoteDataSource(this._api);
  final ApiClient _api;

  Future<List<MemberModel>> list() async {
    final response = await _api.get(ApiConstants.members);
    final data = response.data as Map<String, dynamic>;
    final members = data['members'] as List<dynamic>? ?? [];
    return members
        .map((e) => MemberModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<MemberModel> create({
    required String email,
    required String password,
    String firstName = '',
    String lastName = '',
  }) async {
    final response = await _api.post(ApiConstants.members, data: {
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
    });
    final data = response.data as Map<String, dynamic>;
    return MemberModel.fromJson(Map<String, dynamic>.from(data['member'] as Map));
  }

  Future<void> remove(String memberId) async {
    await _api.delete('${ApiConstants.members}/$memberId');
  }
}

