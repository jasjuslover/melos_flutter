import 'package:customer_app/features/products/domain/product.dart';

abstract interface class ProductRepository {
  Future<ProductPage> fetchPage({String? cursor});

  Future<Product> getById(int id);

  Future<Product> create(ProductInput input);

  Future<Product> update(int id, ProductInput input);

  Future<void> delete(int id);
}
