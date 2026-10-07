class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
  });

  final int id;
  final String name;
  final int price; // rupiah
  final int stock;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as int,
    name: json['name'] as String,
    price: json['price'] as int,
    stock: json['stock'] as int,
  );
}
