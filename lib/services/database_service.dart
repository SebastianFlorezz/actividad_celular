import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

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
  static const _databaseName = 'nexo_inventario.db';
  static const _databaseVersion = 1;
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final databasesPath = await getDatabasesPath();
    _database = await openDatabase(
      path.join(databasesPath, _databaseName),
      version: _databaseVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE proveedores (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL,
            telefono TEXT,
            correo TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE productos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre TEXT NOT NULL,
            precio REAL NOT NULL,
            stock INTEGER NOT NULL,
            proveedor_id INTEGER NOT NULL,
            FOREIGN KEY (proveedor_id) REFERENCES proveedores(id)
              ON UPDATE CASCADE ON DELETE RESTRICT
          )
        ''');
      },
    );
    return _database!;
  }

  Future<List<Supplier>> getSuppliers() async {
    final db = await database;
    final rows = await db.query('proveedores', orderBy: 'nombre COLLATE NOCASE');
    return rows.map(Supplier.fromMap).toList();
  }

  Future<int> saveSupplier(Supplier supplier) async {
    final db = await database;
    if (supplier.id == null) {
      return db.insert('proveedores', supplier.toMap());
    }
    return db.update(
      'proveedores',
      supplier.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [supplier.id],
    );
  }

  Future<int> getSupplierProductCount(int id) async {
    final db = await database;
    return Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM productos WHERE proveedor_id = ?',
            [id],
          ),
        ) ??
        0;
  }

  Future<void> deleteSupplier(
    int id, {
    int? reassignProductsToSupplierId,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      final associated = Sqflite.firstIntValue(
        await txn.rawQuery(
          'SELECT COUNT(*) FROM productos WHERE proveedor_id = ?',
          [id],
        ),
      ) ?? 0;
      if (associated > 0 && reassignProductsToSupplierId == null) {
        throw SupplierHasProductsException(associated);
      }
      if (reassignProductsToSupplierId == id) {
        throw ArgumentError('El proveedor de destino debe ser diferente.');
      }
      if (associated > 0) {
        final destination = await txn.query(
          'proveedores',
          columns: ['id'],
          where: 'id = ?',
          whereArgs: [reassignProductsToSupplierId],
          limit: 1,
        );
        if (destination.isEmpty) {
          throw ArgumentError('El proveedor de destino ya no existe.');
        }
        await txn.update(
          'productos',
          {'proveedor_id': reassignProductsToSupplierId},
          where: 'proveedor_id = ?',
          whereArgs: [id],
        );
      }
      await txn.delete('proveedores', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<List<Product>> getProducts({String query = ''}) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT productos.*, proveedores.nombre AS proveedor_nombre
      FROM productos
      INNER JOIN proveedores ON proveedores.id = productos.proveedor_id
      WHERE productos.nombre LIKE ? COLLATE NOCASE
      ORDER BY productos.nombre COLLATE NOCASE
      ''',
      ['%${query.trim()}%'],
    );
    return rows.map(Product.fromMap).toList();
  }

  Future<int> saveProduct(Product product) async {
    final db = await database;
    if (product.id == null) {
      return db.insert('productos', product.toMap());
    }
    return db.update(
      'productos',
      product.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return db.delete('productos', where: 'id = ?', whereArgs: [id]);
  }

  Future<({int products, int suppliers})> getSummary() async {
    final db = await database;
    final products = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM productos'),
    );
    final suppliers = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM proveedores'),
    );
    return (products: products ?? 0, suppliers: suppliers ?? 0);
  }
}
