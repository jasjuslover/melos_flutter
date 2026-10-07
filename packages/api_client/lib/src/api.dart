import 'package:dio/dio.dart';

import 'api_exception.dart';
import 'product.dart';

class Api {
  Api({
    required String baseUrl,
    required Future<String?> Function() readToken,
    void Function()? onUnauthorized,
  }) : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        )) {
    // Interceptor: tambahkan token ke setiap request secara otomatis.
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await readToken();
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (error, handler) {
        final isAuthEndpoint = error.requestOptions.path.startsWith('/auth/');
        if (error.response?.statusCode == 401 && !isAuthEndpoint) {
          onUnauthorized?.call();
        }
        handler.next(error);
      },
    ));
  }

  final Dio _dio;

  Future<T> _call<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> register(String email, String password) async {
    await _call(() => _dio.post<void>(
          '/auth/register',
          data: {'email': email, 'password': password},
        ));
  }

  /// Mengembalikan access token. Simpan di flutter_secure_storage.
  Future<String> login(String email, String password) => _call(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          '/auth/login',
          data: {'email': email, 'password': password},
        );
        return res.data!['access_token'] as String;
      });

  Future<List<Product>> listProducts({int limit = 20, int offset = 0}) =>
      _call(() async {
        final res = await _dio.get<Map<String, dynamic>>(
          '/products',
          queryParameters: {'limit': limit, 'offset': offset},
        );
        final items = res.data!['items'] as List<dynamic>;
        return items
            .map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  Future<Product> getProduct(int id) => _call(() async {
        final res = await _dio.get<Map<String, dynamic>>('/products/$id');
        return Product.fromJson(res.data!);
      });

  Future<Product> createProduct({
    required String name,
    required int price,
    required int stock,
  }) =>
      _call(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          '/products',
          data: {'name': name, 'price': price, 'stock': stock},
        );
        return Product.fromJson(res.data!);
      });

  Future<Product> updateProduct(
    int id, {
    required String name,
    required int price,
    required int stock,
  }) =>
      _call(() async {
        final res = await _dio.put<Map<String, dynamic>>(
          '/products/$id',
          data: {'name': name, 'price': price, 'stock': stock},
        );
        return Product.fromJson(res.data!);
      });

  Future<void> deleteProduct(int id) async {
    await _call(() => _dio.delete<void>('/products/$id'));
  }
}