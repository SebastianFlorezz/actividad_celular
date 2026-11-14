class Product {
  const Product({
    this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.supplierId,
    this.supplierName,
  });

  final int? id;
  final String name;
  final double price;
  final int stock;
  final int supplierId;
  final String? supplierName;

  Map<String, Object?> toMap() => {
    'id': id,
    'nombre': name.trim(),
    'precio': price,
    'stock': stock,
    'proveedor_id': supplierId,
  };

  factory Product.fromMap(Map<String, Object?> map) => Product(
    id: map['id'] as int,
    name: map['nombre'] as String,
    price: (map['precio'] as num).toDouble(),
    stock: map['stock'] as int,
    supplierId: map['proveedor_id'] as int,
    supplierName: map['proveedor_nombre'] as String?,
  );
}
