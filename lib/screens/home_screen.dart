import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dashboard_screen.dart';
import 'products_screen.dart';
import 'suppliers_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _dataVersion = 0;

  static const _titles = ['Nexo Inventario', 'Productos', 'Proveedores'];

  void _onDataChanged() {
    setState(() => _dataVersion++);
  }

  void _selectPage(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cerrar sesión: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
        key: ValueKey(_dataVersion),
        onNavigate: _selectPage,
      ),
      ProductsScreen(
        key: ValueKey('products-$_dataVersion'),
        onDataChanged: _onDataChanged,
      ),
      SuppliersScreen(
        key: ValueKey('suppliers-$_dataVersion'),
        onDataChanged: _onDataChanged,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _titles[_selectedIndex],
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
            ),
            if (_selectedIndex == 0)
              const Text(
                'CONTROL DE INVENTARIO',
                style: TextStyle(
                  color: Color(0xFF82908C),
                  fontSize: 9,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        actions: [
          if (_selectedIndex == 0)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: CircleAvatar(
                radius: 19,
                backgroundColor: const Color(0xFFE5F1ED),
                child: Icon(
                  Icons.inventory_2_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 19,
                ),
              ),
            ),
          IconButton(
            tooltip: 'Sincronizar con la base de datos',
            onPressed: _onDataChanged,
            icon: const Icon(Icons.sync_rounded),
          ),
          PopupMenuButton<String>(
            tooltip: 'Cuenta',
            onSelected: (value) {
              if (value == 'signOut') _signOut();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Text(
                  Supabase.instance.client.auth.currentUser?.email ?? '',
                ),
              ),
              const PopupMenuItem(
                value: 'signOut',
                child: Text('Cerrar sesión'),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: pages),
      floatingActionButton: _selectedIndex == 1 || _selectedIndex == 2
          ? FloatingActionButton.extended(
              onPressed: () async {
                if (_selectedIndex == 1) {
                  await ProductsScreen.openForm(context);
                } else {
                  await SuppliersScreen.openForm(context);
                }
                if (mounted) _onDataChanged();
              },
              icon: const Icon(Icons.add_rounded),
              label: Text(_selectedIndex == 1 ? 'Nuevo producto' : 'Nuevo proveedor'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectPage,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2_rounded),
            label: 'Productos',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping_rounded),
            label: 'Proveedores',
          ),
        ],
      ),
    );
  }
}
