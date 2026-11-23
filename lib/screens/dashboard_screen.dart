import 'package:flutter/material.dart';

import '../services/database_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.onNavigate,
  });

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final summary = DatabaseService.instance.getSummary();
    return FutureBuilder(
      future: summary,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('No se pudo cargar el resumen: ${snapshot.error}'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final totals = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: const LinearGradient(
                  colors: [Color(0xFF146E5E), Color(0xFF21947A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -9,
                    bottom: -19,
                    child: Icon(
                      Icons.inventory_2_rounded,
                      size: 130,
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          'TU NEGOCIO, EN ORDEN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 17),
                      const Text(
                        'Todo tu inventario\nbajo control.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          height: 1.18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Consulta y administra tus productos y proveedores.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.83),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF176D5C),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 11,
                          ),
                        ),
                        onPressed: () => onNavigate(1),
                        child: const Text('Ver productos'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Resumen general', style: Theme.of(context).textTheme.titleLarge),
                const Text(
                  'SINCRONIZADO',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.1,
                    color: Color(0xFF87938F),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Productos',
                    value: totals.products,
                    caption: 'registrados',
                    icon: Icons.inventory_2_rounded,
                    color: const Color(0xFF167D68),
                    onTap: () => onNavigate(1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    title: 'Proveedores',
                    value: totals.suppliers,
                    caption: 'registrados',
                    icon: Icons.local_shipping_rounded,
                    color: const Color(0xFFE39A38),
                    onTap: () => onNavigate(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            Text('Accesos rápidos', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 13),
            _QuickAction(
              icon: Icons.add_box_rounded,
              title: 'Administrar productos',
              subtitle: 'Consulta stock, precios y proveedores',
              onTap: () => onNavigate(1),
            ),
            const SizedBox(height: 10),
            _QuickAction(
              icon: Icons.group_add_rounded,
              title: 'Administrar proveedores',
              subtitle: 'Mantén tus contactos actualizados',
              onTap: () => onNavigate(2),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2EF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: Color(0xFF167D68)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tus datos se sincronizan con Supabase y están protegidos por tu cuenta.',
                      style: TextStyle(
                        color: Color(0xFF49655D),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.caption,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final int value;
  final String caption;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 19, color: color),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF657184),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 17),
            Text(
              '$value',
              style: const TextStyle(
                color: Color(0xFF172B4D),
                fontSize: 32,
                height: 1,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(caption, style: const TextStyle(fontSize: 11, color: Color(0xFF87938F))),
          ],
        ),
      ),
    ),
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(17),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2EF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFF167D68)),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF9AA5A1)),
          ],
        ),
      ),
    ),
  );
}
