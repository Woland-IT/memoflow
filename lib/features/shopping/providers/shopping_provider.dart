import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/shopping_item_model.dart';

class ShoppingProvider with ChangeNotifier {
  final Box<ShoppingItem> _box = Hive.box<ShoppingItem>('shopping_items');
  final supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  List<ShoppingItem> get activeItems => 
      _box.values.where((item) => !item.isChecked).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  List<ShoppingItem> get archivedItems => 
      _box.values.where((item) => item.isChecked).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  final List<String> commonCategories = ['Warzywa', 'Owoce', 'Mięso', 'Nabiał', 'Pieczywo', 'Napoje', 'Słodycze', 'Chemia', 'Inne'];

  Future<void> addItem(String name, {String? category, String quantity = "1 szt."}) async {
    final item = ShoppingItem(
      id: _uuid.v4(),
      name: name.trim(),
      category: category,
      quantity: quantity,
      isChecked: false,
      createdAt: DateTime.now(),
    );

    await _box.put(item.id, item);
    notifyListeners();
    await _syncToSupabase(item);
  }

  Future<void> toggleCheck(String id) async {
    final item = _box.get(id);
    if (item == null) return;
    item.isChecked = !item.isChecked;
    await item.save();
    notifyListeners();
    await _syncToSupabase(item);
  }

  Future<void> finishAllActive() async {
    final active = _box.values.where((item) => !item.isChecked).toList();
    for (var item in active) {
      item.isChecked = true;
      await item.save();
      await _syncToSupabase(item);
    }
    notifyListeners();
  }

  Future<void> deleteItem(String id) async {
    await _box.delete(id);
    notifyListeners();
    try {
      await supabase.from('shopping_items').delete().eq('id', id);
    } catch (e) {}
  }

  Future<void> _syncToSupabase(ShoppingItem item) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Tworzymy lub pobieramy domyślną listę zakupów
      var listResponse = await supabase
          .from('shopping_lists')
          .select('id')
          .eq('user_id', user.id)
          .limit(1);

      String listId;
      if (listResponse.isEmpty) {
        final newList = await supabase
            .from('shopping_lists')
            .insert({'user_id': user.id, 'name': 'Moja lista'})
            .select()
            .single();
        listId = newList['id'];
      } else {
        listId = listResponse[0]['id'];
      }

      await supabase.from('shopping_items').upsert({
        'id': item.id,
        'list_id': listId,
        'name': item.name,
        'quantity': item.quantity,
        'is_checked': item.isChecked,
        'category': item.category,
        'created_at': item.createdAt.toIso8601String(),
      }, onConflict: 'id');

      print('✅ Produkt zsynchronizowany');
    } catch (e) {
      print('❌ Błąd sync zakupów: $e');
    }
  }

  Future<void> loadFromSupabase() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await supabase
          .from('shopping_items')
          .select()
          .eq('list_id', (await supabase.from('shopping_lists').select('id').eq('user_id', user.id).limit(1)).first['id']);

      for (var json in response) {
        final item = ShoppingItem.fromJson(json);
        await _box.put(item.id, item);
      }
      notifyListeners();
      print('✅ Pobrano zakupy z Supabase');
    } catch (e) {
      print('Błąd pobierania zakupów: $e');
    }
  }
}