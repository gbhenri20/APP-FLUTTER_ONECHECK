class AppException implements Exception {
  const AppException(
    this.message, {
    this.statusCode,
    this.code,
    this.cause,
  });

  final String message;
  final int? statusCode;
  final String? code;
  final Object? cause;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isValidation => statusCode == 422 || statusCode == 400;
  bool get isConflict => statusCode == 409;
  bool get isRateLimited => statusCode == 429;
  bool get isServerError => (statusCode ?? 0) >= 500;
  bool get isNetwork => code == 'network' || code == 'timeout';

  @override
  String toString() => 'AppException($statusCode): $message';
}

class SessionExpiredException extends AppException {
  const SessionExpiredException([
    super.message = 'Sessão expirada. Faça login novamente.',
  ]) : super(statusCode: 401, code: 'session_expired');
}
