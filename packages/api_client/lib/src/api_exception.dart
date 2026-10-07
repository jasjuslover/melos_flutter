import 'package:dio/dio.dart';

class ApiException implements Exception {
  ApiException(this.statusCode, this.code, this.message);

  final int? statusCode;
  final String code; // contoh: EMAIL_TAKEN, NOT_FOUND, UNAUTHORIZED
  final String message; // pesan dari server, siap ditampilkan

  factory ApiException.fromDio(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      return ApiException(
        e.response?.statusCode,
        data['code'] as String? ?? 'UNKNOWN',
        data['message'] as String? ?? 'Terjadi kesalahan',
      );
    }
    return ApiException(null, 'NETWORK', 'Koneksi internet bermasalah');
  }

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}
