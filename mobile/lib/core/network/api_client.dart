import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:purchase_journal/core/constants/api_constants.dart';
import 'package:purchase_journal/core/constants/app_constants.dart';
import 'package:purchase_journal/core/error/error_message_mapper.dart';
import 'package:purchase_journal/core/error/exceptions.dart';
import 'package:purchase_journal/core/network/token_storage.dart';

class ApiClient {
  ApiClient(this._tokenStorage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.apiBaseUrl,
        connectTimeout: const Duration(milliseconds: AppConstants.connectionTimeout),
        receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
        headers: ApiConstants.defaultHeaders,
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(_tokenStorage),
      _RefreshInterceptor(_dio, _tokenStorage),
      _EnvelopeInterceptor(),
      if (kDebugMode) _LoggingInterceptor(),
      _ErrorInterceptor(),
    ]);
  }

  final TokenStorage _tokenStorage;
  late final Dio _dio;

  Future<Response<T>> postMultipart<T>(String path, FormData formData) {
    return _dio.post<T>(path, data: formData);
  }

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get<T>(path, queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(String path, {dynamic data}) {
    return _dio.post<T>(path, data: data);
  }

  Future<Response<T>> put<T>(String path, {dynamic data}) {
    return _dio.put<T>(path, data: data);
  }

  Future<Response<T>> patch<T>(String path, {dynamic data}) {
    return _dio.patch<T>(path, data: data);
  }

  Future<Response<T>> delete<T>(String path) {
    return _dio.delete<T>(path);
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._tokenStorage);
  final TokenStorage _tokenStorage;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokenStorage.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

class _RefreshInterceptor extends Interceptor {
  _RefreshInterceptor(this._dio, this._tokenStorage);
  final Dio _dio;
  final TokenStorage _tokenStorage;

  static bool _refreshing = false;
  static Future<bool>? _refreshFuture;

  static const _skip = {
    ApiConstants.authLogin,
    ApiConstants.authRegister,
    ApiConstants.authRefresh,
  };

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final path = err.requestOptions.path;
    if (err.response?.statusCode != 401 ||
        _skip.any((p) => path.endsWith(p)) ||
        err.requestOptions.extra['retried'] == true) {
      return handler.next(err);
    }

    final ok = await _refresh();
    if (!ok) {
      await _tokenStorage.clearToken();
      return handler.next(err);
    }

    try {
      final request = err.requestOptions;
      request.headers['Authorization'] = 'Bearer ${await _tokenStorage.getToken()}';
      request.extra['retried'] = true;
      final response = await _dio.fetch(request);
      return handler.resolve(response);
    } catch (_) {
      return handler.next(err);
    }
  }

  Future<bool> _refresh() async {
    if (_refreshing && _refreshFuture != null) return _refreshFuture!;
    _refreshing = true;
    _refreshFuture = _doRefresh();
    try {
      return await _refreshFuture!;
    } finally {
      _refreshing = false;
      _refreshFuture = null;
    }
  }

  Future<bool> _doRefresh() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final bare = Dio(BaseOptions(
        baseUrl: ApiConstants.apiBaseUrl,
        headers: ApiConstants.defaultHeaders,
      ));
      final response = await bare.post(
        ApiConstants.authRefresh,
        data: {'refreshToken': refreshToken},
      );
      final body = response.data;
      if (body is! Map || body['success'] != true) return false;
      final data = body['data'];
      if (data is! Map) return false;
      final access = data['accessToken'] as String?;
      final refresh = data['refreshToken'] as String?;
      if (access == null || refresh == null) return false;
      await _tokenStorage.saveTokens(accessToken: access, refreshToken: refresh);
      return true;
    } catch (_) {
      return false;
    }
  }
}

class _EnvelopeInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final data = response.data;
    if (data is Map<String, dynamic> && data['success'] == true) {
      response.data = data['data'];
    } else if (data is Map<String, dynamic> && data['success'] == false) {
      handler.reject(
        DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: data['error']?.toString() ?? 'Request failed',
        ),
      );
      return;
    }
    super.onResponse(response, handler);
  }
}

class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('REQUEST ${options.method} ${options.uri}');
    super.onRequest(options, handler);
  }
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final mapped = _map(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: mapped,
        message: mapped.message,
      ),
    );
  }

  AppException _map(DioException err) {
    if (err.type == DioExceptionType.connectionError) {
      return const NetworkException(message: 'No internet connection');
    }
    final status = err.response?.statusCode;
    final data = err.response?.data;
    final message = ErrorMessageMapper.extractApiErrorMessage(data) ?? 'Request failed';
    if (status == 401) return AuthenticationException(message: message);
    return ServerException(message: message, statusCode: status);
  }
}
