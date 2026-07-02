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
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => _showClearArchivedDialog(context, provider),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildActiveTab(context, provider),
            _buildArchivedTab(provider),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddDialog(context, provider),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildActiveTab(BuildContext context, ShoppingProvider provider) {
    final items = provider.activeItems;
    if (items.isEmpty) {
      return const Center(child: Text('Brak aktywnych produktów\nDodaj pierwsze zakupy!'));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            onPressed: () => provider.finishAllActive(),
            icon: const Icon(Icons.done_all),
            label: const Text('Zakończ całą listę'),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.shopping_cart_outlined, color: Colors.teal),
                  title: Text(item.name),
                  subtitle: Text('${item.quantity} • ${item.category ?? "Brak kategorii"}'),
                  trailing: Checkbox(
                    value: item.isChecked,
                    onChanged: (_) => provider.toggleCheck(item.id),
                  ),
                  onLongPress: () => _confirmDelete(context, provider, item.id),
                ),
              );
            },
          ),
        ),
      ],
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
          subtitle: Text('${item.quantity} • ${item.category ?? ""}'),
          onLongPress: () => _confirmDelete(context, provider, item.id),
        );
      },
    );
  }

  // ... (metody dialogów — mogę dodać ulepszoną wersję z kategoriami jeśli chcesz)

  void _showAddDialog(BuildContext context, ShoppingProvider provider) {
    // Aktualna wersja + kategorie (można rozbudować)
    final nameController = TextEditingController();
    final quantityController = TextEditingController(text: "1 szt.");
    String? selectedCategory;

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
              decoration: const InputDecoration(labelText: 'Ilość'),
            ),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Kategoria'),
              items: provider.commonCategories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
              onChanged: (val) => selectedCategory = val,
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
                  category: selectedCategory,
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
        title: const Text('Usunąć produkt?'),
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

  void _showClearArchivedDialog(BuildContext context, ShoppingProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wyczyścić archiwum?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Anuluj')),
          TextButton(
            onPressed: () {
              provider.clearArchived();
              Navigator.pop(context);
            },
            child: const Text('Wyczyść', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}