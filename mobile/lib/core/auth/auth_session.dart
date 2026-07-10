import 'package:flutter/material.dart';
import 'package:purchase_journal/core/error/error_message_mapper.dart';
import 'package:purchase_journal/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:purchase_journal/features/auth/data/models/user_model.dart';
import 'package:purchase_journal/core/network/token_storage.dart';

enum AuthStatus { unknown, authenticated, unauthenticated, pendingVerification }

class AuthSession extends ChangeNotifier {
  AuthSession(this._auth, this._tokens);

  final AuthRemoteDataSource _auth;
  final TokenStorage _tokens;

  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  String? _error;
  String? _errorCode;
  String? _pendingEmail;
  String? _devCode;
  bool _loading = false;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get error => _error;
  String? get errorCode => _errorCode;
  String? get pendingEmail => _pendingEmail ?? _user?.email;
  String? get devCode => _devCode;
  bool get isLoading => _loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get needsEmailVerification => _status == AuthStatus.pendingVerification;

  Future<void> bootstrap() async {
    final token = await _tokens.getToken();
    if (token == null || token.isEmpty) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      _user = await _auth.getMe();
      _pendingEmail = _user!.email;
      _status = _user!.emailVerified
          ? AuthStatus.authenticated
          : AuthStatus.pendingVerification;
    } catch (_) {
      await _tokens.clearToken();
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    return _run(() async {
      final result = await _auth.login(email: email, password: password);
      await _apply(result);
      return true;
    }, onError: (e) {
      final authError = ErrorMessageMapper.asAuthenticationException(e);
      if (authError != null) {
        _errorCode = authError.code;
        if (authError.isEmailNotVerified) {
          _pendingEmail = email;
          _status = AuthStatus.unauthenticated;
        }
      }
    });
  }

  Future<bool> register({
    required String email,
    required String password,
    String firstName = '',
    String lastName = '',
  }) async {
    return _run(() async {
      final result = await _auth.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
      _devCode = result['devCode'] as String?;
      _pendingEmail = email;
      await _apply(result);
      return true;
    });
  }

  Future<bool> verifyEmail({required String email, required String code}) async {
    return _run(() async {
      final result = await _auth.verifyEmail(email: email, code: code);
      _devCode = null;
      await _apply(result);
      return true;
    });
  }

  Future<bool> resendVerification(String email) async {
    return _run(() async {
      _devCode = await _auth.resendVerification(email: email);
      _pendingEmail = email;
      return true;
    });
  }

  Future<String?> forgotPassword(String email) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final code = await _auth.forgotPassword(email: email);
      _devCode = code;
      notifyListeners();
      return code;
    } catch (e) {
      _error = ErrorMessageMapper.message(e);
      notifyListeners();
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    return _run(() async {
      await _auth.resetPassword(email: email, code: code, password: password);
      _devCode = null;
      return true;
    });
  }

  Future<void> logout() async {
    await _tokens.clearToken();
    _user = null;
    _pendingEmail = null;
    _devCode = null;
    _errorCode = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    if (_status != AuthStatus.authenticated && _status != AuthStatus.pendingVerification) {
      return;
    }
    try {
      _user = await _auth.getMe();
      _pendingEmail = _user!.email;
      _status = _user!.emailVerified
          ? AuthStatus.authenticated
          : AuthStatus.pendingVerification;
      if (_user!.emailVerified) _devCode = null;
      notifyListeners();
    } catch (_) {
      // Keep current status if refresh fails.
    }
  }

  void clearError() {
    _error = null;
    _errorCode = null;
    notifyListeners();
  }

  Future<bool> _run(
    Future<bool> Function() action, {
    void Function(Object error)? onError,
  }) async {
    _loading = true;
    _error = null;
    _errorCode = null;
    notifyListeners();
    try {
      return await action();
    } catch (e) {
      _error = ErrorMessageMapper.message(e);
      onError?.call(e);
      notifyListeners();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _apply(Map<String, dynamic> result) async {
    final access = result['accessToken'] as String;
    final refresh = result['refreshToken'] as String;
    await _tokens.saveTokens(accessToken: access, refreshToken: refresh);
    _user = UserModel.fromJson(Map<String, dynamic>.from(result['user'] as Map));
    _pendingEmail = _user!.email;
    if (result['devCode'] != null) _devCode = result['devCode'] as String?;
    _status = _user!.emailVerified
        ? AuthStatus.authenticated
        : AuthStatus.pendingVerification;
    notifyListeners();
  }
}
