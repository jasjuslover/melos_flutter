import 'dart:async';

import 'package:customer_app/core/providers.dart';
import 'package:customer_app/features/products/data/api_product_repository.dart';
import 'package:customer_app/features/products/domain/product.dart';
import 'package:customer_app/features/products/domain/product_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductsState {
  const ProductsState({
    required this.items,
    this.nextCursor,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  final List<Product> items;
  final String? nextCursor;
  final bool isLoadingMore;
  final Object? loadMoreError;

  ProductsState copyWith({
    List<Product>? items,
    String? nextCursor,
    bool? isLoadingMore,
    Object? loadMoreError,
  }) {
    return ProductsState(
      items: items ?? this.items,
      nextCursor: nextCursor,
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
  ProductRepository get _repo => ref.read(productRepositoryProvider);
  static const pageSize = 20;

  @override
  FutureOr<ProductsState> build() async {
    final page = await ref.watch(productRepositoryProvider).fetchPage();
    return ProductsState(items: page.items, nextCursor: page.nextCursor);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final page = await _repo.fetchPage(cursor: current.nextCursor);
      if (!ref.mounted) return;
      state = AsyncData(
        current.copyWith(
          items: [...current.items, ...page.items],
          isLoadingMore: false,
          nextCursor: page.nextCursor,
        ),
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = AsyncData(
        current.copyWith(isLoadingMore: false, loadMoreError: e),
      );
    }
  }

  Future<void> create(ProductInput input) async {
    final product = await _repo.create(input);
    _apply((s) => s.copyWith(items: [product, ...s.items]));
  }

  Future<void> edit(int id, ProductInput input) async {
    final updated = await _repo.update(id, input);
    _apply(
      (s) => s.copyWith(
        items: [for (final p in s.items) p.id == id ? updated : p],
      ),
    );
  }

  Future<void> remove(int id) async {
    await _repo.delete(id);
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
  return ref.watch(productRepositoryProvider).getById(id);
});
