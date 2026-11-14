import 'package:flutter/material.dart';

import '../models/supplier.dart';
import '../services/database_service.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key, required this.onDataChanged});

  final VoidCallback onDataChanged;

  static Future<bool?> openForm(
    BuildContext context, {
    Supplier? supplier,
  }) => Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => SupplierFormScreen(supplier: supplier)),
  );

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  late Future<List<Supplier>> _suppliers;

  @override
  void initState() {
    super.initState();
    _suppliers = DatabaseService.instance.getSuppliers();
  }

  Future<void> _reload() async {
    final suppliers = await DatabaseService.instance.getSuppliers();
    if (!mounted) return;
    setState(() {
      _suppliers = Future.value(suppliers);
    });
  }

  void _reloadFromAction() {
    _reload().catchError((Object error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron cargar los proveedores: $error')),
      );
    });
  }

  Future<void> _edit(Supplier? supplier) async {
    final saved = await SuppliersScreen.openForm(context, supplier: supplier);
    if (saved == true && mounted) {
      await _reload();
      if (!mounted) return;
      widget.onDataChanged();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(supplier == null ? 'Proveedor guardado.' : 'Proveedor actualizado.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _delete(Supplier supplier) async {
    try {
      final service = DatabaseService.instance;
      final productCount = await service.getSupplierProductCount(supplier.id!);
      if (!mounted) return;
      int? destinationId;
      if (productCount > 0) {
        final alternatives = (await service.getSuppliers())
            .where((candidate) => candidate.id != supplier.id)
            .toList();
        if (!mounted) return;
        if (alternatives.isEmpty) {
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('No se puede eliminar todavía'),
              content: Text(
                '${supplier.name} tiene $productCount '
                '${productCount == 1 ? 'producto asociado' : 'productos asociados'}. '
                'Registra otro proveedor para transferirlos antes de eliminarlo.',
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Entendido'),
                ),
              ],
            ),
          );
          return;
        }
        destinationId = await showDialog<int>(
          context: context,
          builder: (context) {
            int? selectedId;
            return StatefulBuilder(
              builder: (context, setDialogState) => AlertDialog(
                title: const Text('Transferir productos'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${supplier.name} tiene $productCount '
                      '${productCount == 1 ? 'producto asociado' : 'productos asociados'}. '
                      'Elige a quién transferirlos antes de eliminar este proveedor.',
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      initialValue: selectedId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Nuevo proveedor',
                        prefixIcon: Icon(Icons.local_shipping_outlined),
                      ),
                      items: alternatives
                          .map(
                            (candidate) => DropdownMenuItem(
                              value: candidate.id!,
                              child: Text(
                                candidate.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setDialogState(() => selectedId = value),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFB63F39),
                    ),
                    onPressed: selectedId == null
                        ? null
                        : () => Navigator.pop(context, selectedId),
                    child: const Text('Transferir y eliminar'),
                  ),
                ],
              ),
            );
          },
        );
        if (destinationId == null) return;
      } else {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Eliminar proveedor'),
            content: Text('¿Quieres eliminar a "${supplier.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB63F39),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
      }
      await service.deleteSupplier(
        supplier.id!,
        reassignProductsToSupplierId: destinationId,
      );
      if (!mounted) return;
      await _reload();
      if (!mounted) return;
      widget.onDataChanged();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            destinationId == null
                ? 'Proveedor eliminado.'
                : '$productCount ${productCount == 1 ? 'producto transferido' : 'productos transferidos'} y proveedor eliminado.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on SupplierHasProductsException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo completar la eliminación: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar el proveedor: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
    children: [
      Text('Tus proveedores', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 5),
      const Text('Organiza tus contactos y sus datos de comunicación.'),
      const SizedBox(height: 21),
      FutureBuilder<List<Supplier>>(
        future: _suppliers,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _SupplierEmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Ocurrió un problema',
              message: 'No se pudieron cargar los proveedores: ${snapshot.error}',
              actionLabel: 'Reintentar',
              onAction: _reloadFromAction,
            );
          }
          if (!snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final suppliers = snapshot.data!;
          if (suppliers.isEmpty) {
            return _SupplierEmptyState(
              icon: Icons.local_shipping_outlined,
              title: 'Aún no hay proveedores',
              message: 'Registra tus contactos para asociarlos a tus productos.',
              actionLabel: 'Agregar proveedor',
              onAction: () => _edit(null),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  '${suppliers.length} ${suppliers.length == 1 ? 'proveedor' : 'proveedores'}',
                  style: const TextStyle(
                    color: Color(0xFF87938F),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...suppliers.map(
                (supplier) => Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: _SupplierCard(
                    supplier: supplier,
                    onEdit: () => _edit(supplier),
                    onDelete: () => _delete(supplier),
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

class _SupplierCard extends StatelessWidget {
  const _SupplierCard({
    required this.supplier,
    required this.onEdit,
    required this.onDelete,
  });

  final Supplier supplier;
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
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 47,
          height: 47,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E2),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(Icons.storefront_rounded, color: Color(0xFFD58B2E)),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                supplier.name,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              if (supplier.phone != null) ...[
                const SizedBox(height: 9),
                _ContactLine(icon: Icons.phone_outlined, text: supplier.phone!),
              ],
              if (supplier.email != null) ...[
                const SizedBox(height: 7),
                _ContactLine(icon: Icons.mail_outline_rounded, text: supplier.email!),
              ],
              if (supplier.phone == null && supplier.email == null) ...[
                const SizedBox(height: 7),
                const Text(
                  'Sin datos de contacto',
                  style: TextStyle(fontSize: 12, color: Color(0xFF899490)),
                ),
              ],
            ],
          ),
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
  );
}

class _ContactLine extends StatelessWidget {
  const _ContactLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 15, color: const Color(0xFF87938F)),
      const SizedBox(width: 7),
      Expanded(
        child: Text(
          text,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: Color(0xFF657184)),
        ),
      ),
    ],
  );
}

class SupplierFormScreen extends StatefulWidget {
  const SupplierFormScreen({super.key, this.supplier});

  final Supplier? supplier;

  @override
  State<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends State<SupplierFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.supplier?.name ?? '');
    _phoneController = TextEditingController(text: widget.supplier?.phone ?? '');
    _emailController = TextEditingController(text: widget.supplier?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await DatabaseService.instance.saveSupplier(
        Supplier(
          id: widget.supplier?.id,
          name: _nameController.text,
          phone: _phoneController.text,
          email: _emailController.text,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar el proveedor: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.supplier == null ? 'Nuevo proveedor' : 'Editar proveedor'),
    ),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.storefront_rounded, color: Color(0xFFD58B2E)),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Datos del proveedor', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 3),
                    const Text('El nombre es obligatorio. Los demás datos son opcionales.', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SupplierFieldLabel('Nombre o razón social'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Ej. Distribuidora Central',
              prefixIcon: Icon(Icons.business_outlined),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Ingresa el nombre del proveedor'
                : null,
          ),
          const SizedBox(height: 18),
          const _SupplierFieldLabel('Teléfono'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              hintText: 'Número de contacto',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 18),
          const _SupplierFieldLabel('Correo electrónico'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'correo@ejemplo.com',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
            validator: (value) {
              final email = value?.trim() ?? '';
              if (email.isNotEmpty &&
                  !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                return 'Ingresa un correo válido';
              }
              return null;
            },
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
            label: Text(_saving ? 'Guardando...' : 'Guardar proveedor'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
          ),
        ],
      ),
    ),
  );
}

class _SupplierFieldLabel extends StatelessWidget {
  const _SupplierFieldLabel(this.label);

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

class _SupplierEmptyState extends StatelessWidget {
  const _SupplierEmptyState({
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
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
    child: Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(color: Color(0xFFFFF3E2), shape: BoxShape.circle),
          child: Icon(icon, size: 29, color: const Color(0xFFD58B2E)),
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
