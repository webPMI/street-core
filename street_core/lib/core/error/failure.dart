import 'package:equatable/equatable.dart';

/// Base class for all semantic failures in the application.
/// Carries a localization key instead of a hardcoded technical string.
abstract class Failure extends Equatable {
  const Failure(this.messageKey, {this.code});
  final String messageKey;
  final String? code;

  @override
  List<Object?> get props => [messageKey, code];

  @override
  String toString() => 'Failure(key: $messageKey, code: $code)';
}

/// Generic failure for unexpected errors.
class ServerFailure extends Failure {
  const ServerFailure({String? messageKey, String? code})
    : super(messageKey ?? 'error.server_default', code: code);
}

/// Connection or timeout failures.
class NetworkFailure extends Failure {
  const NetworkFailure() : super('error.network_connection');
}

/// Authentication and authorization failures.
class AuthFailure extends Failure {
  const AuthFailure(super.messageKey, {super.code});
}

/// Validation or business logic failures from the backend.
class BusinessFailure extends Failure {
  const BusinessFailure(super.messageKey, {super.code});
}
