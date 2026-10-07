import 'package:api_client/api_client.dart' as api;
import 'package:customer_app/core/api_guard.dart';
import 'package:customer_app/core/providers.dart';
import 'package:customer_app/features/products/domain/product.dart';
import 'package:customer_app/features/products/domain/product_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => ApiProductRepository(ref.watch(apiProvider)),
);

class ApiProductRepository implements ProductRepository {
  ApiProductRepository(this._api);

  final api.Api _api;

  static const pageSize = 20;

  @override
  Future<ProductPage> fetchPage({String? cursor}) async {
    final offset = int.tryParse(cursor ?? '') ?? 0;
    final dtos = await _api.listProducts(limit: pageSize, offset: offset);
    return ProductPage(
      items: dtos.map(_toEntity).toList(),
      nextCursor: dtos.length == pageSize ? '${offset + dtos.length}' : null,
    );
  }

  @override
  Future<Product> create(ProductInput input) async {
    final dto = await _api.createProduct(
      name: input.name,
      price: input.price,
      stock: input.stock,
    );
    return Product(
      id: dto.id,
      name: dto.name,
      price: dto.price,
      stock: dto.stock,
    );
  }

  @override
  Future<Product> getById(int id) async {
    final dto = await _api.getProduct(id);
    return Product(
      id: dto.id,
      name: dto.name,
      price: dto.price,
      stock: dto.stock,
    );
  }

  @override
  Future<Product> update(int id, ProductInput input) async {
    final dto = await _api.updateProduct(
      id,
      name: input.name,
      price: input.price,
      stock: input.stock,
    );
    return Product(
      id: dto.id,
      name: dto.name,
      price: dto.price,
      stock: dto.stock,
    );
  }

  @override
  Future<void> delete(int id) => guardApi(() => _api.deleteProduct(id));

  static Product _toEntity(api.Product dto) =>
      Product(id: dto.id, name: dto.name, price: dto.price, stock: dto.stock);
}
