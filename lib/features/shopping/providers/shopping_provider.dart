import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/shopping_item_model.dart';

class ShoppingProvider with ChangeNotifier {
  final Box<ShoppingItem> _box = Hive.box<ShoppingItem>('shopping_items');

  List<ShoppingItem> get activeItems => 
      _box.values.where((item) => !item.isChecked).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  List<ShoppingItem> get archivedItems => 
      _box.values.where((item) => item.isChecked).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  // Predefiniowane kategorie
  final List<String> commonCategories = [
    'Warzywa', 'Owoce', 'Mięso', 'Nabiał', 'Pieczywo', 
    'Napoje', 'Słodycze', 'Chemia', 'Inne'
  ];

  Future<void> addItem(String name, {String? category, String quantity = "1 szt."}) async {
    final item = ShoppingItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      category: category,
      quantity: quantity,
      createdAt: DateTime.now(),
    );
    await _box.put(item.id, item);
    notifyListeners();
  }

  Future<void> toggleCheck(String id) async {
    final item = _box.get(id);
    if (item != null) {
      item.isChecked = !item.isChecked;
      await item.save();
      notifyListeners();
    }
  }

  // Nowa metoda: zakończ wszystkie aktywne
  Future<void> finishAllActive() async {
    final active = _box.values.where((item) => !item.isChecked).toList();
    for (var item in active) {
      item.isChecked = true;
      await item.save();
    }
    notifyListeners();
  }

  Future<void> deleteItem(String id) async {
    await _box.delete(id);
    notifyListeners();
  }

  // Opcjonalnie: wyczyść archiwum
  Future<void> clearArchived() async {
    final archived = _box.values.where((item) => item.isChecked).toList();
    for (var item in archived) {
      await _box.delete(item.id);
    }
    notifyListeners();
  }
}