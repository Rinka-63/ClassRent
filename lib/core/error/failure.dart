sealed class Failure {
  const Failure(this.message, {this.code});

  final String message;
  final String? code;
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code});
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message, {super.code});
}

class UnknownFailure extends Failure {
  const UnknownFailure(this.message) : super(message);
  final String message;
  
  @override
  String toString() => 'UnknownFailure: $message';
}
