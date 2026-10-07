sealed class Failure implements Exception {
  const Failure(this.message);

  final String message;

  @override
  String toString() => '$runtimeType($message)';
}

final class NetworkFailure extends Failure {
  const NetworkFailure() : super('Internet connection problem');
}

final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure(super.message);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class ConflictFailure extends Failure {
  const ConflictFailure(super.message);
}

final class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server went wrong. Try again later.']);
}
