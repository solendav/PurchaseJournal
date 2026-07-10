import 'package:purchase_journal/core/constants/api_constants.dart';
import 'package:purchase_journal/core/network/api_client.dart';
import 'package:purchase_journal/features/auth/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> login({required String email, required String password});
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String firstName,
    String lastName,
  });
  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  });
  Future<String?> resendVerification({required String email});
  Future<String?> forgotPassword({required String email});
  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
  });
  Future<UserModel> getMe();
  Future<UserModel> updateProfile({
    String? firstName,
    String? lastName,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  @override
  Future<Map<String, dynamic>> login({required String email, required String password}) async {
    final response = await _api.post(ApiConstants.authLogin, data: {
      'email': email,
      'password': password,
    });
    return Map<String, dynamic>.from(response.data as Map);
  }

  @override
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String firstName = '',
    String lastName = '',
  }) async {
    final response = await _api.post(ApiConstants.authRegister, data: {
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
    });
    return Map<String, dynamic>.from(response.data as Map);
  }

  @override
  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async {
    final response = await _api.post(ApiConstants.authVerifyEmail, data: {
      'email': email,
      'code': code,
    });
    return Map<String, dynamic>.from(response.data as Map);
  }

  @override
  Future<String?> resendVerification({required String email}) async {
    final response = await _api.post(ApiConstants.authResendVerification, data: {
      'email': email,
    });
    final data = response.data as Map<String, dynamic>;
    return data['devCode'] as String?;
  }

  @override
  Future<String?> forgotPassword({required String email}) async {
    final response = await _api.post(ApiConstants.authForgotPassword, data: {
      'email': email,
    });
    final data = response.data as Map<String, dynamic>;
    return data['devCode'] as String?;
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    await _api.post(ApiConstants.authResetPassword, data: {
      'email': email,
      'code': code,
      'password': password,
    });
  }

  @override
  Future<UserModel> getMe() async {
    final response = await _api.get(ApiConstants.authMe);
    final data = response.data as Map<String, dynamic>;
    return UserModel.fromJson(Map<String, dynamic>.from(data['user'] as Map));
  }

  @override
  Future<UserModel> updateProfile({
    String? firstName,
    String? lastName,
  }) async {
    final response = await _api.patch(ApiConstants.authMe, data: {
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
    });
    final data = response.data as Map<String, dynamic>;
    return UserModel.fromJson(Map<String, dynamic>.from(data['user'] as Map));
  }
}
