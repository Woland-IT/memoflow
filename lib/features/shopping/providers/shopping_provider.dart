import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/shopping_item_model.dart';

class ShoppingProvider with ChangeNotifier {
  final Box<ShoppingItem> _box = Hive.box<ShoppingItem>('shopping_items');

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<ShoppingItem> get activeItems => 
      _box.values.where((item) => !item.isChecked).toList()..sort((a, b) => a.name.compareTo(b.name));

  List<ShoppingItem> get archivedItems => 
      _box.values.where((item) => item.isChecked).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Future<void> addItem(String name, {String? category, String quantity = "1 szt."}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (name.trim().isEmpty) throw Exception('Nazwa przedmiotu nie może być pusta');
      final item = ShoppingItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name.trim(),
        category: category,
        quantity: quantity,
        createdAt: DateTime.now(),
      );
      await _box.put(item.id, item);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleCheck(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final item = _box.get(id);
      if (item != null) {
        item.isChecked = !item.isChecked;
        await item.save();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteItem(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _box.delete(id);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> finishAllActive() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final active = activeItems;
      for (var item in active) {
        item.isChecked = true;
        await item.save();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}