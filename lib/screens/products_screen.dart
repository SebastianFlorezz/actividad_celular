import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/product.dart';
import '../models/supplier.dart';
import '../services/database_service.dart';
import 'product_detail_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key, required this.onDataChanged});

  final VoidCallback onDataChanged;

  static Future<bool?> openForm(
    BuildContext context, {
    Product? product,
  }) => Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)),
  );

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _searchController = TextEditingController();
  late Future<List<Product>> _products;

  @override
  void initState() {
    super.initState();
    _products = DatabaseService.instance.getProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _products = DatabaseService.instance.getProducts(
        query: _searchController.text,
      );
    });
  }

  Future<void> _edit(Product? product) async {
    final saved = await ProductsScreen.openForm(context, product: product);
    if (saved == true && mounted) {
      _reload();
      widget.onDataChanged();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(product == null ? 'Producto guardado.' : 'Producto actualizado.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showDetails(Product product) async {
    final action = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(product: product),
      ),
    );
    if (!mounted) return;
    if (action == 'edit') {
      await _edit(product);
    } else if (action == 'delete') {
      await _delete(product);
    }
  }

  Future<void> _delete(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Quieres eliminar "${product.name}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB63F39)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await DatabaseService.instance.deleteProduct(product.id!);
      if (!mounted) return;
      _reload();
      widget.onDataChanged();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto eliminado.'), behavior: SnackBarBehavior.floating),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar el producto: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
    children: [
      Text(
        'Tu catálogo',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 5),
      const Text('Revisa existencias, precios y quién los suministra.'),
      const SizedBox(height: 18),
      TextField(
        controller: _searchController,
        onChanged: (_) => _reload(),
        decoration: const InputDecoration(
          hintText: 'Buscar producto por nombre',
          prefixIcon: Icon(Icons.search_rounded),
        ),
      ),
      const SizedBox(height: 19),
      FutureBuilder<List<Product>>(
        future: _products,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorPanel(
              message: 'No se pudieron cargar los productos: ${snapshot.error}',
              onRetry: _reload,
            );
          }
          if (!snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final products = snapshot.data!;
          if (products.isEmpty) {
            return _EmptyPanel(
              icon: Icons.inventory_2_outlined,
              title: _searchController.text.isEmpty
                  ? 'Aún no hay productos'
                  : 'No encontramos resultados',
              message: _searchController.text.isEmpty
                  ? 'Agrega tu primer producto y asígnalo a un proveedor.'
                  : 'Prueba con otro nombre o limpia la búsqueda.',
              actionLabel: _searchController.text.isEmpty ? 'Agregar producto' : null,
              onAction: _searchController.text.isEmpty ? () => _edit(null) : null,
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  '${products.length} ${products.length == 1 ? 'producto' : 'productos'}',
                  style: const TextStyle(
                    color: Color(0xFF87938F),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...products.map(
                (product) => Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: _ProductCard(
                    product: product,
                    onDetails: () => _showDetails(product),
                    onEdit: () => _edit(product),
                    onDelete: () => _delete(product),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ],
  );
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.onDetails,
    required this.onEdit,
    required this.onDelete,
  });

  final Product product;
  final VoidCallback onDetails;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFEDF0EF)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2EF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.widgets_rounded, color: Color(0xFF167D68)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.supplierName ?? 'Proveedor sin nombre',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF7C8985)),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Ver detalle',
              onPressed: onDetails,
              icon: const Icon(Icons.open_in_new_rounded),
            ),
            PopupMenuButton<String>(
              tooltip: 'Opciones',
              onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Editar')),
                PopupMenuItem(value: 'delete', child: Text('Eliminar')),
              ],
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Divider(height: 1, color: Color(0xFFEDF0EF)),
        ),
        Row(
          children: [
            _ProductMetric(
              label: 'PRECIO',
              value: '\$${product.price.toStringAsFixed(2)}',
              icon: Icons.sell_outlined,
            ),
            const SizedBox(width: 25),
            _ProductMetric(
              label: 'EXISTENCIAS',
              value: '${product.stock} unidades',
              icon: Icons.inventory_outlined,
            ),
          ],
        ),
      ],
    ),
  );
}

class _ProductMetric extends StatelessWidget {
  const _ProductMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Row(
      children: [
        Icon(icon, size: 17, color: const Color(0xFF82908C)),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  letterSpacing: 0.7,
                  color: Color(0xFF98A29F),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF172B4D),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.product});

  final Product? product;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late Future<List<Supplier>> _suppliers;
  int? _supplierId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _priceController = TextEditingController(
      text: widget.product?.price.toString() ?? '',
    );
    _stockController = TextEditingController(
      text: widget.product?.stock.toString() ?? '',
    );
    _supplierId = widget.product?.supplierId;
    _suppliers = DatabaseService.instance.getSuppliers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_supplierId == null) return;
    setState(() => _saving = true);
    try {
      await DatabaseService.instance.saveProduct(
        Product(
          id: widget.product?.id,
          name: _nameController.text,
          price: double.parse(_priceController.text.trim().replaceAll(',', '.')),
          stock: int.parse(_stockController.text.trim()),
          supplierId: _supplierId!,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar el producto: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.product == null ? 'Nuevo producto' : 'Editar producto'),
    ),
    body: FutureBuilder<List<Supplier>>(
      future: _suppliers,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('No se pudieron cargar los proveedores: ${snapshot.error}'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final suppliers = snapshot.data!;
        final selectedSupplierId = suppliers.any(
          (supplier) => supplier.id == _supplierId,
        )
            ? _supplierId
            : null;
        if (suppliers.isEmpty) {
          return _EmptyPanel(
            icon: Icons.local_shipping_outlined,
            title: 'Necesitas un proveedor',
            message: 'Registra primero un proveedor para poder asociarlo al producto.',
            actionLabel: 'Volver',
            onAction: () => Navigator.pop(context),
          );
        }
        return Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            children: [
              const _FormIntro(
                icon: Icons.inventory_2_rounded,
                title: 'Información del producto',
                subtitle: 'Completa los datos para mantener tu catálogo al día.',
              ),
              const SizedBox(height: 23),
              const _FieldLabel('Nombre del producto'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Ej. Café molido',
                  prefixIcon: Icon(Icons.widgets_outlined),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Ingresa el nombre del producto'
                    : null,
              ),
              const SizedBox(height: 17),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel('Precio unitario'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*([.,]\d{0,2})?$')),
                          ],
                          decoration: const InputDecoration(
                            hintText: '0.00',
                            prefixText: '\$ ',
                          ),
                          validator: (value) {
                            final price = double.tryParse(
                              (value ?? '').trim().replaceAll(',', '.'),
                            );
                            if (price == null || price < 0) return 'Precio inválido';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel('Existencias'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _stockController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(hintText: '0'),
                          validator: (value) => int.tryParse(value ?? '') == null
                              ? 'Cantidad inválida'
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 17),
              const _FieldLabel('Proveedor'),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: selectedSupplierId,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.local_shipping_outlined),
                  hintText: 'Selecciona un proveedor',
                ),
                items: suppliers
                    .map(
                      (supplier) => DropdownMenuItem(
                        value: supplier.id,
                        child: Text(supplier.name, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _supplierId = value),
                validator: (value) => value == null ? 'Selecciona un proveedor' : null,
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(_saving ? 'Guardando...' : 'Guardar producto'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _FormIntro extends StatelessWidget {
  const _FormIntro({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFEAF2EF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: const Color(0xFF167D68)),
      ),
      const SizedBox(width: 13),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 3),
            Text(subtitle, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    ],
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: Color(0xFF34445D),
      fontWeight: FontWeight.w700,
      fontSize: 13,
    ),
  );
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(24, 35, 24, 30),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: Color(0xFFEAF2EF),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 29, color: const Color(0xFF167D68)),
        ),
        const SizedBox(height: 15),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 7),
        Text(message, textAlign: TextAlign.center),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 17),
          FilledButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ],
    ),
  );
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => _EmptyPanel(
    icon: Icons.error_outline_rounded,
    title: 'Ocurrió un problema',
    message: message,
    actionLabel: 'Reintentar',
    onAction: onRetry,
  );
}
