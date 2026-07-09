import 'package:flutter/material.dart';
import 'package:purchase_journal/core/error/error_message_mapper.dart';
import 'package:purchase_journal/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:purchase_journal/features/auth/data/models/user_model.dart';
import 'package:purchase_journal/core/network/token_storage.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthSession extends ChangeNotifier {
  AuthSession(this._auth, this._tokens);

  final AuthRemoteDataSource _auth;
  final TokenStorage _tokens;

  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  String? _error;
  bool _loading = false;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get error => _error;
  bool get isLoading => _loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> bootstrap() async {
    final token = await _tokens.getToken();
    if (token == null || token.isEmpty) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      _user = await _auth.getMe();
      _status = AuthStatus.authenticated;
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
      await _apply(result);
      return true;
    });
  }

  Future<void> logout() async {
    await _tokens.clearToken();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    if (_status != AuthStatus.authenticated) return;
    _user = await _auth.getMe();
    notifyListeners();
  }

  Future<bool> _run(Future<bool> Function() action) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      return await action();
    } catch (e) {
      _error = ErrorMessageMapper.message(e);
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
    _status = AuthStatus.authenticated;
    notifyListeners();
  }
}
