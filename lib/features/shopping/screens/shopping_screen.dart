import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/shopping_item_model.dart';
import '../providers/shopping_provider.dart';

class ShoppingScreen extends StatelessWidget {
  const ShoppingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShoppingProvider>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Listy zakupów'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Aktywne'),
              Tab(text: 'Zarchiwizowane'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildActiveTab(provider),
            _buildArchivedTab(provider),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showSimpleAddDialog(context, provider),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildActiveTab(ShoppingProvider provider) {
    final items = provider.activeItems;
    if (items.isEmpty) {
      return const Center(child: Text('Brak aktywnych produktów\nDodaj pierwsze zakupy!'));
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
                return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            leading: const Icon(Icons.shopping_cart_outlined, color: Colors.teal),
            title: Text(item.name),
            subtitle: Text('${item.quantity} ${item.category ?? ""}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _showEditItemDialog(context, provider, item),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                  onPressed: () => _confirmDelete(context, provider, item.id),
                ),
              ],
            ),
            onLongPress: () => _confirmDelete(context, provider, item.id), // zostaw na razie
          ),
        );
      },
    );
  }

  Widget _buildArchivedTab(ShoppingProvider provider) {
    final items = provider.archivedItems;
    if (items.isEmpty) {
      return const Center(child: Text('Brak zarchiwizowanych zakupów'));
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          leading: const Icon(Icons.check_circle, color: Colors.grey),
          title: Text(item.name, style: const TextStyle(decoration: TextDecoration.lineThrough)),
          subtitle: Text(item.quantity),
          onLongPress: () => _confirmDelete(context, provider, item.id),
        );
      },
    );
  }

  void _showSimpleAddDialog(BuildContext context, ShoppingProvider provider) {
    final nameController = TextEditingController();
    final quantityController = TextEditingController(text: "1 szt.");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nowy produkt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nazwa produktu'),
              autofocus: true,
            ),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(labelText: 'Ilość (np. 300g, 2 szt.)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Anuluj')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                provider.addItem(
                  nameController.text,
                  quantity: quantityController.text.trim(),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Dodaj'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, ShoppingProvider provider, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usunąć?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Anuluj')),
          TextButton(
            onPressed: () {
              provider.deleteItem(id);
              Navigator.pop(context);
            },
            child: const Text('Usuń', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  void _showEditItemDialog(BuildContext context, ShoppingProvider provider, ShoppingItem item) {
    final nameController = TextEditingController(text: item.name);
    final quantityController = TextEditingController(text: item.quantity ?? "1 szt.");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edytuj produkt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nazwa produktu'),
            ),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(labelText: 'Ilość'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteItem(item.id); // tymczasowo usuwamy stare
              provider.addItem(
                nameController.text.trim(),
                quantity: quantityController.text.trim(),
              );
              Navigator.pop(context);
            },
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );
  }
    
}