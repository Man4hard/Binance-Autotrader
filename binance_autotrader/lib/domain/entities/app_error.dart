sealed class AppError {
  final String message;
  const AppError(this.message);
}

class NetworkError extends AppError {
  final int? statusCode;
  const NetworkError(super.message, {this.statusCode});
}

class BinanceApiError extends AppError {
  final int code;
  const BinanceApiError(super.message, {required this.code});
}

class RateLimitError extends AppError {
  final int retryAfterMs;
  const RateLimitError(super.message, {required this.retryAfterMs});
}

class AuthenticationError extends AppError {
  const AuthenticationError(super.message);
}

class StorageError extends AppError {
  const StorageError(super.message);
}

class ValidationError extends AppError {
  const ValidationError(super.message);
}

class InsufficientFundsError extends AppError {
  const InsufficientFundsError(super.message);
}

class UnknownError extends AppError {
  final Object? cause;
  const UnknownError(super.message, {this.cause});
}
