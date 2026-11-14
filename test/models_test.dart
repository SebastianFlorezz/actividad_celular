import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_local/models/product.dart';
import 'package:inventario_local/models/supplier.dart';

void main() {
  group('Supplier', () {
    test('trims fields and stores optional empty values as null', () {
      final supplier = Supplier(
        name: '  Distribuidora  ',
        phone: '  ',
        email: ' compras@example.com ',
      );

      expect(supplier.toMap(), {
        'id': null,
        'nombre': 'Distribuidora',
        'telefono': null,
        'correo': 'compras@example.com',
      });
    });

    test('maps a database row to a supplier', () {
      final supplier = Supplier.fromMap({
        'id': 4,
        'nombre': 'Mercado Norte',
        'telefono': null,
        'correo': 'hola@example.com',
      });

      expect(supplier.id, 4);
      expect(supplier.name, 'Mercado Norte');
      expect(supplier.email, 'hola@example.com');
    });
  });

  group('Product', () {
    test('maps a database row including the joined supplier name', () {
      final product = Product.fromMap({
        'id': 8,
        'nombre': 'Café',
        'precio': 12,
        'stock': 3,
        'proveedor_id': 4,
        'proveedor_nombre': 'Mercado Norte',
      });

      expect(product.price, 12.0);
      expect(product.supplierId, 4);
      expect(product.supplierName, 'Mercado Norte');
    });

    test('serializes product fields for SQLite', () {
      final product = Product(
        id: 8,
        name: '  Café ',
        price: 12.5,
        stock: 3,
        supplierId: 4,
      );

      expect(product.toMap(), {
        'id': 8,
        'nombre': 'Café',
        'precio': 12.5,
        'stock': 3,
        'proveedor_id': 4,
      });
    });
  });
}
