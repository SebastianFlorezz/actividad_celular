import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';
import '../models/supplier.dart';

class SupplierHasProductsException implements Exception {
  const SupplierHasProductsException(this.productCount);

  final int productCount;

  @override
  String toString() =>
      'No se puede eliminar el proveedor: tiene $productCount productos asociados.';
}

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();
  final SupabaseClient _client = Supabase.instance.client;

  String get _userId {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Debes iniciar sesión para acceder a los datos.');
    }
    return userId;
  }

  Future<List<Supplier>> getSuppliers() async {
    final rows = await _client
        .from('proveedores')
        .select()
        .order('nombre');
    return rows.map(Supplier.fromMap).toList();
  }

  Future<int> saveSupplier(Supplier supplier) async {
    if (supplier.id == null) {
      final values = supplier.toMap()..remove('id');
      final result = await _client
          .from('proveedores')
          .insert({...values, 'owner_id': _userId})
          .select('id')
          .single();
      return result['id'] as int;
    }
    final result = await _client
        .from('proveedores')
        .update(supplier.toMap()..remove('id'))
        .eq('id', supplier.id!)
        .select('id')
        .single();
    return result['id'] as int;
  }

  Future<int> getSupplierProductCount(int id) async {
    final products = await _client
        .from('productos')
        .select('id')
        .eq('proveedor_id', id);
    return products.length;
  }

  Future<void> deleteSupplier(
    int id, {
    int? reassignProductsToSupplierId,
  }) async {
    final associated = await getSupplierProductCount(id);
    if (associated > 0 && reassignProductsToSupplierId == null) {
      throw SupplierHasProductsException(associated);
    }
    if (reassignProductsToSupplierId == id) {
      throw ArgumentError('El proveedor de destino debe ser diferente.');
    }
    await _client.rpc(
      'eliminar_proveedor',
      params: {
        'p_supplier_id': id,
        'p_destination_id': reassignProductsToSupplierId,
      },
    );
  }

  Future<List<Product>> getProducts({String query = ''}) async {
    final trimmedQuery = query.trim();
    final rows = trimmedQuery.isEmpty
        ? await _client
              .from('productos')
              .select('*, proveedores(nombre)')
              .order('nombre')
        : await _client
              .from('productos')
              .select('*, proveedores(nombre)')
              .ilike('nombre', '%$trimmedQuery%')
              .order('nombre');
    return rows.map((row) {
      final supplier = row['proveedores'] as Map<String, dynamic>?;
      return Product.fromMap({
        ...row,
        'proveedor_nombre': supplier?['nombre'],
      });
    }).toList();
  }

  Future<int> saveProduct(Product product) async {
    if (product.id == null) {
      final values = product.toMap()..remove('id');
      final result = await _client
          .from('productos')
          .insert({...values, 'owner_id': _userId})
          .select('id')
          .single();
      return result['id'] as int;
    }
    final result = await _client
        .from('productos')
        .update(product.toMap()..remove('id'))
        .eq('id', product.id!)
        .select('id')
        .single();
    return result['id'] as int;
  }

  Future<int> deleteProduct(int id) async {
    final result = await _client
        .from('productos')
        .delete()
        .eq('id', id)
        .select('id');
    return result.length;
  }

  Future<({int products, int suppliers})> getSummary() async {
    final products = await _client.from('productos').select('id');
    final suppliers = await _client.from('proveedores').select('id');
    return (products: products.length, suppliers: suppliers.length);
  }
}
