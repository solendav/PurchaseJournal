import 'package:dio/dio.dart';
import 'package:purchase_journal/core/error/exceptions.dart';

class ErrorMessageMapper {
  ErrorMessageMapper._();

  static const genericFallback = 'Something went wrong. Please try again.';
  static const credentialsMismatch = 'Email or password is incorrect.';

  static String message(Object error, {String? fallback}) {
    final defaultFallback = fallback ?? genericFallback;

    if (error is DioException) {
      final inner = error.error;
      if (inner is AppException) {
        return message(inner, fallback: fallback);
      }
      return _fromDio(error, defaultFallback);
    }

    if (error is AuthenticationException) {
      return _friendlyAuthMessage(error.message);
    }
    if (error is ServerException) {
      return _sanitize(error.message, defaultFallback);
    }
    if (error is NetworkException) {
      return _sanitize(error.message, defaultFallback);
    }
    if (error is AppException) {
      return _sanitize(error.message, defaultFallback);
    }

    return _sanitize(error.toString(), defaultFallback);
  }

  static String _fromDio(DioException error, String fallback) {
    final data = error.response?.data;
    final apiMessage = extractApiErrorMessage(data);
    final status = error.response?.statusCode;

    if (status == 401) {
      return _friendlyAuthMessage(apiMessage ?? credentialsMismatch);
    }

    if (apiMessage != null) {
      return _sanitize(apiMessage, fallback);
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Please try again.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network.';
      case DioExceptionType.badResponse:
        if (status == 403) return 'You do not have permission to do that.';
        if (status == 404) return 'The requested item was not found.';
        if (status == 429) return 'Too many attempts. Please try again later.';
        if (status != null && status >= 500) {
          return 'Server is unavailable. Please try again later.';
        }
        return fallback;
      default:
        return fallback;
    }
  }

  static String? extractApiErrorMessage(dynamic data) {
    if (data is String && data.trim().isNotEmpty) return data.trim();
    if (data is Map) {
      final errors = data['errors'];
      if (errors is List && errors.isNotEmpty) {
        final first = errors.first;
        if (first is Map) {
          final fieldMessage = first['message']?.toString().trim();
          if (fieldMessage != null && fieldMessage.isNotEmpty) {
            return fieldMessage;
          }
        }
      }

      final error = data['error']?.toString().trim();
      if (error != null && error.isNotEmpty) {
        if (error.toLowerCase() == 'validation failed') {
          return 'Please check your details and try again.';
        }
        return error;
      }

      final message = data['message']?.toString().trim();
      if (message != null && message.isNotEmpty) return message;
    }
    return null;
  }

  static String _friendlyAuthMessage(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('invalid email or password') ||
        lower.contains('email or password') ||
        lower.contains('authentication failed') ||
        lower.contains('unauthorized')) {
      return credentialsMismatch;
    }
    return _sanitize(raw, credentialsMismatch);
  }

  static String _sanitize(String raw, String fallback) {
    var text = raw.trim();
    if (text.isEmpty) return fallback;

    const prefixes = [
      'ServerException: ',
      'NetworkException: ',
      'AuthenticationException: ',
      'AppException: ',
      'Exception: ',
      'DioException ',
      'DioException: ',
    ];
    for (final prefix in prefixes) {
      if (text.startsWith(prefix)) {
        text = text.substring(prefix.length).trim();
      }
    }

    text = text.replaceAll(RegExp(r'^(\[bad response\]):?\s*', caseSensitive: false), '').trim();
    text = text.replaceAll(RegExp(r'^Error:\s*', caseSensitive: false), '').trim();

    if (text.isEmpty || _looksTechnical(text)) return fallback;

    final lower = text.toLowerCase();
    if (lower == 'validation failed') {
      return 'Please check your details and try again.';
    }
    if (lower.contains('invalid email or password')) {
      return credentialsMismatch;
    }

    return text;
  }

  static bool _looksTechnical(String text) {
    final lower = text.toLowerCase();
    return lower.contains('dioexception') ||
        lower.contains('bad response') ||
        lower.contains('stack trace') ||
        lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('type \'') ||
        lower.contains('null check');
  }
}
