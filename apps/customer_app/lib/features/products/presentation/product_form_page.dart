import 'package:customer_app/features/products/domain/product.dart';
import 'package:customer_app/features/products/presentation/products_controller.dart';
import 'package:customer_app/shared/error_view.dart';
import 'package:customer_app/shared/messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProductFormPage extends ConsumerWidget {
  const new({super.key, this.productId});

  final int? productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = productId;
    return Scaffold(
      appBar: AppBar(title: Text(id == null ? "Add Product" : "Edit Product")),
      body: id == null
          ? const _ProductForm()
          : ref
                .watch(productDetailProvider(id))
                .when(
                  data: (product) => _ProductForm(initial: product),
                  error: (error, _) => ErrorView(
                    message: messageOf(error),
                    onRetry: () => ref.invalidate(productDetailProvider),
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                ),
    );
  }
}

class _ProductForm extends ConsumerStatefulWidget {
  const new({super.key, this.initial});

  final Product? initial;

  @override
  ConsumerState<_ProductForm> createState() => __ProductFormState();
}

class __ProductFormState extends ConsumerState<_ProductForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _price = TextEditingController(
    text: widget.initial?.price.toString(),
  );
  late final _stock = TextEditingController(
    text: widget.initial?.stock.toString(),
  );
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _stock.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
    });

    final controller = ref.read(productsControllerProvider.notifier);
    final input = ProductInput(
      name: _name.text.trim(),
      price: int.parse(_price.text),
      stock: int.parse(_stock.text),
    );
    final initial = widget.initial;

    try {
      if (initial == null) {
        controller.create(input);
      } else {
        controller.edit(initial.id, input);
      }
      if (!mounted) return;
      showSnack(context, initial == null ? "Product added" : "Product updated");
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
      });
      showSnack(context, messageOf(e));
    }
  }

  String? _validateNumber(String? value, String label) {
    if (value == null || value.isEmpty) return '$label is required';
    if (int.tryParse(value) == null) return '$label is invalid';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: "Product name"),
            textInputAction: TextInputAction.next,
            maxLength: 200,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Name is required' : null,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _price,
            decoration: const InputDecoration(
              labelText: 'Price',
              prefixText: 'Rp',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textInputAction: TextInputAction.next,
            validator: (v) => _validateNumber(v, 'Price'),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _stock,
            decoration: const InputDecoration(labelText: 'Stock'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textInputAction: TextInputAction.next,
            validator: (v) => _validateNumber(v, 'Stock'),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
    );
  }
}
