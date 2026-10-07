import 'package:api_client/api_client.dart';
import 'package:customer_app/core/failure.dart';

Future<T> guardApi<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on ApiException catch (e) {
    throw failureFromApi(e);
  }
}

Failure failureFromApi(ApiException e) {
  return switch (e.statusCode) {
    null => const NetworkFailure(), // tidak ada respons dari server
    401 => UnauthorizedFailure(e.message),
    404 => NotFoundFailure(e.message),
    409 => ConflictFailure(e.message),
    400 || 422 => ValidationFailure(e.message),
    _ => const ServerFailure(),
  };
}
