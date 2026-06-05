sealed class Failure {
  const Failure(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => code == null ? message : '$code: $message';
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
  const UnknownFailure(super.message, {super.code});
}
