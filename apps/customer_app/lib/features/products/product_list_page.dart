import 'package:api_client/api_client.dart';
import 'package:customer_app/features/auth/auth_controller.dart';
import 'package:customer_app/features/products/products_controller.dart';
import 'package:customer_app/shared/error_view.dart';
import 'package:customer_app/shared/formatters.dart';
import 'package:customer_app/shared/messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProductListPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Products'),
        actions: [
          IconButton(
            onPressed: () => ref.read(authControllerProvider.notifier),
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/products/new'),
        label: const Text('Add'),
        icon: const Icon(Icons.add),
      ),
      body: products.when(
        data: (state) => RefreshIndicator(
          onRefresh: () => ref.refresh(productsControllerProvider.future),
          child: state.items.isEmpty
              ? const _EmptyView()
              : _ProductList(state: state),
        ),
        error: (error, _) => ErrorView(
          message: messageOf(error),
          onRetry: () => ref.invalidate(productsControllerProvider),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ProductList extends StatelessWidget {
  const _ProductList({required this.state});

  final ProductsState state;

  @override
  Widget build(BuildContext context) {
    return NotificationListener(
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 96),
        itemBuilder: (context, index) {
          if (index == state.items.length) return _ListFooter(state: state);
          final product = state.items[index];
          return _ProductTile(key: ValueKey(product.id), product: product);
        },
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemCount: state.items.length + 1,
      ),
    );
  }
}

class _ProductTile extends ConsumerWidget {
  const new({super.key, required this.product});

  final Product product;

  void _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('"${product.name}" will be deleted permanently'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(productsControllerProvider.notifier).remove(product.id);
      if (context.mounted) showSnack(context, 'Product deleted');
    } catch (e) {
      if (context.mounted) showSnack(context, messageOf(e));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: Text(product.name),
      subtitle: Text('${formatRupiah(product.price)} · Stock ${product.stock}'),
      onTap: () => context.push('/products/${product.id}/edit'),
      trailing: IconButton(
        onPressed: () => _confirmDelete(context, ref),
        icon: const Icon(Icons.delete_outline),
      ),
    );
  }
}

class _ListFooter extends ConsumerWidget {
  const _ListFooter({required this.state});

  final ProductsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Center(
          child: TextButton.icon(
            onPressed: () =>
                ref.read(productsControllerProvider.notifier).loadMore(),
            icon: const Icon(Icons.refresh),
            label: const Text('Failed to load data. Please try again'),
          ),
        ),
      );
    }
    if (!state.hasMore) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            'All products is displayed',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }
    return const SizedBox(height: 16);
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 80),
        Icon(
          Icons.inventory_2_outlined,
          size: 64,
          color: Theme.of(context).colorScheme.outline,
        ),
        const SizedBox(height: 16),
        Text(
          'No product',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'Press the button to create your first product.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}