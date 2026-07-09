class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ServerException extends AppException {
  const ServerException({required String message, this.statusCode}) : super(message);
  final int? statusCode;
}

class NetworkException extends AppException {
  const NetworkException({required String message}) : super(message);
}

class AuthenticationException extends AppException {
  const AuthenticationException({required String message}) : super(message);
}
