import 'dart:async';

import 'package:api_client/api_client.dart';
import 'package:customer_app/core/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductsState {
  const ProductsState({
    required this.items,
    required this.hasMore,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  final List<Product> items;
  final bool hasMore;
  final bool isLoadingMore;
  final Object? loadMoreError;

  ProductsState copyWith({
    List<Product>? items,
    bool? hasMore,
    bool? isLoadingMore,
    Object? loadMoreError,
  }) {
    return ProductsState(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError: loadMoreError,
    );
  }
}

final productsControllerProvider =
    AsyncNotifierProvider.autoDispose<ProductsController, ProductsState>(
      ProductsController.new,
    );

class ProductsController extends AsyncNotifier<ProductsState> {
  static const pageSize = 20;

  Api get _api => ref.read(apiProvider);

  @override
  FutureOr<ProductsState> build() async {
    final items = await ref
        .watch(apiProvider)
        .listProducts(limit: pageSize, offset: 0);
    return ProductsState(items: items, hasMore: items.length == pageSize);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final next = await _api.listProducts(
        limit: pageSize,
        offset: current.items.length,
      );
      if (!ref.mounted) return;
      state = AsyncData(
        current.copyWith(
          items: [...current.items, ...next],
          hasMore: next.length == pageSize,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = AsyncData(
        current.copyWith(isLoadingMore: false, loadMoreError: e),
      );
    }
  }

  Future<void> create({
    required String name,
    required int price,
    required int stock,
  }) async {
    final product = await _api.createProduct(
      name: name,
      price: price,
      stock: stock,
    );
    _apply((s) => s.copyWith(items: [product, ...s.items]));
  }

  Future<void> edit(
    int id, {
    required String name,
    required int price,
    required int stock,
  }) async {
    final updated = await _api.updateProduct(
      id,
      name: name,
      price: price,
      stock: stock,
    );
    _apply(
      (s) => s.copyWith(
        items: [for (final p in s.items) p.id == id ? updated : p],
      ),
    );
  }

  Future<void> remove(int id) async {
    await _api.deleteProduct(id);
    _apply((s) => s.copyWith(items: s.items.where((p) => p.id != id).toList()));
  }

  void _apply(ProductsState Function(ProductsState) change) {
    final current = state.value;
    if (current != null && ref.mounted) state = AsyncData(change(current));
  }
}

final productDetailProvider = FutureProvider.autoDispose.family<Product, int>((
  ref,
  id,
) {
  return ref.watch(apiProvider).getProduct(id);
});
