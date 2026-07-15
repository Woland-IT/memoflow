import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/shopping_item_model.dart';
import '../providers/shopping_provider.dart';

import '../models/shopping_product_model.dart';   // ← DODAJ

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
            leading: Checkbox(
              value: item.isChecked,
              onChanged: (value) async {
                await provider.toggleCheck(item.id); // archiwizacja
              },
            ),
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
          leading: const Icon(Icons.check_circle, color: Colors.green),
          title: Text(
            item.name,
            style: const TextStyle(decoration: TextDecoration.lineThrough),
          ),
          subtitle: Text(item.quantity),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _confirmDelete(context, provider, item.id),
          ),
          onLongPress: () => _confirmDelete(context, provider, item.id),
        );
      },
    );
  }

  // ====================== DIALOG DODAWANIA ======================
  void _showSimpleAddDialog(BuildContext context, ShoppingProvider provider) {
    final nameController = TextEditingController();
    final quantityController = TextEditingController(text: "1 szt.");
    final searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Pokazujemy WSZYSTKIE produkty (aktywne + zarchiwizowane)
          final allItems = provider.allItems.where((item) =>
            item.name.toLowerCase().contains(searchController.text.toLowerCase())
          ).toList();

          return AlertDialog(
            title: const Text('Dodaj produkt do listy'),
            content: SizedBox(
              width: 750,
              height: 520,
              child: Row(
                children: [
                  // Lewa strona - ręczne dodanie
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Nowy produkt', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(labelText: 'Nazwa produktu'),
                        ),
                        TextField(
                          controller: quantityController,
                          decoration: const InputDecoration(labelText: 'Ilość'),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () async {
                            if (nameController.text.trim().isEmpty) return;
                            await provider.addItem(
                              nameController.text.trim(),
                              quantity: quantityController.text.trim(),
                            );
                            if (context.mounted) Navigator.pop(context);
                          },
                          child: const Text('Dodaj nowy'),
                        ),
                      ],
                    ),
                  ),
                  const VerticalDivider(thickness: 1),
                  // Prawa strona - wyszukiwarka po wszystkich zakupach
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Wyszukaj wśród wszystkich zakupów', 
                          style: TextStyle(fontWeight: FontWeight.bold)),
                        TextField(
                          controller: searchController,
                          decoration: const InputDecoration(
                            labelText: 'Szukaj produktu...',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: allItems.isEmpty
                              ? const Center(child: Text('Brak wyników'))
                              : ListView.builder(
                                  itemCount: allItems.length,
                                  itemBuilder: (context, index) {
                                    final item = allItems[index];
                                    return ListTile(
                                      leading: Icon(
                                        item.isChecked 
                                            ? Icons.check_circle 
                                            : Icons.shopping_cart_outlined,
                                        color: item.isChecked ? Colors.green : Colors.teal,
                                      ),
                                      title: Text(item.name),
                                      subtitle: Text('${item.quantity} ${item.isChecked ? "(zarchiwizowany)" : ""}'),
                                      onTap: () {
                                        _showQuantityDialog(
                                          context, 
                                          provider, 
                                          item.name, 
                                          item.category,
                                        );
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Anuluj')),
            ],
          );
        },
      ),
    );
  }

  // Nowy dialog z ilością
   void _showQuantityDialog(BuildContext context, ShoppingProvider provider, String name, String? category) {
    final qtyController = TextEditingController(text: "1 szt.");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ile $name?'),
        content: TextField(
          controller: qtyController,
          decoration: const InputDecoration(labelText: 'Ilość'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () async {
              await provider.addItem(
                name,
                category: category,
                quantity: qtyController.text.trim(),
              );
              if (context.mounted) {
                Navigator.pop(context); // zamknij quantity dialog
                Navigator.pop(context); // zamknij główny dialog
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
            onPressed: () async {
              await provider.deleteItem(item.id);
              await provider.addItem(
                nameController.text.trim(),
                quantity: quantityController.text.trim(),
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );
  }
}