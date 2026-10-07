class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
  });

  final int id;
  final String name;
  final int price;
  final int stock;

  bool get isOutOfStock => stock == 0;

  @override
  bool operator ==(Object other) =>
      other is Product &&
      other.id == id &&
      other.name == name &&
      other.price == price &&
      other.stock == stock;

  @override
  int get hashCode => Object.hash(id, name, price, stock);
}

class ProductInput {
  const ProductInput({
    required this.name,
    required this.price,
    required this.stock,
  });

  final String name;
  final int price;
  final int stock;
}

class ProductPage {
  const ProductPage({required this.items, this.nextCursor});

  final List<Product> items;

  final String? nextCursor;
}
