class ServerException implements Exception {
  final String message;
  ServerException(this.message);
}

class CacheException implements Exception {
  final String message;
  CacheException(this.message);
}

class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}

class NotFoundException implements Exception {
  final String message;
  NotFoundException(this.message);
}