import 'package:flutter/material.dart';

import '../models/product.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Detalle del producto')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.inventory_2_rounded,
                size: 38,
                color: Color(0xFF167D68),
              ),
              const SizedBox(height: 17),
              Text(product.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 20),
              _DetailLine(label: 'Precio unitario', value: '\$${product.price.toStringAsFixed(2)}'),
              _DetailLine(label: 'Existencias', value: '${product.stock} unidades'),
              _DetailLine(label: 'Proveedor', value: product.supplierName ?? 'Sin proveedor'),
              _DetailLine(label: 'Identificador', value: '${product.id}'),
            ],
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: () => Navigator.pop(context, 'edit'),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Editar producto'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => Navigator.pop(context, 'delete'),
          icon: const Icon(Icons.delete_outline_rounded),
          label: const Text('Eliminar producto'),
          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFB63F39)),
        ),
      ],
    ),
  );
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF7C8985), fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
}
