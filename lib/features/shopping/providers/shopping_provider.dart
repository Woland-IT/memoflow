import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/shopping_item_model.dart';
import '../repositories/shopping_product_repository.dart';
import '../models/shopping_product_model.dart';

class ShoppingProvider with ChangeNotifier {
  late final Box<ShoppingItem> _box;
  final supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  final ShoppingProductRepository _productRepo = ShoppingProductRepository();

  List<ShoppingItem> get activeItems => 
      _box.values.where((item) => !item.isChecked).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  List<ShoppingItem> get archivedItems => 
      _box.values.where((item) => item.isChecked).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  final List<String> commonCategories = ['Warzywa', 'Owoce', 'Mięso', 'Nabiał', 'Pieczywo', 'Napoje', 'Słodycze', 'Chemia', 'Inne'];

  ShoppingProvider() {
    _init();
  }

  Future<void> _init() async {
    // Inicjalizacja boxa dla ShoppingItem
    if (!Hive.isBoxOpen('shopping_items')) {
      _box = await Hive.openBox<ShoppingItem>('shopping_items');
    } else {
      _box = Hive.box<ShoppingItem>('shopping_items');
    }

    // Inicjalizacja repo produktów (już obsługuje asynchronicznie)
await _productRepo.init();
await _productRepo.printBoxInfo(); // do debugu

    print('✅ Hive boxes otwarte - produktów: ${(await _productRepo.getAll()).length}');
  }

  // ==================== AUTOUZUPEŁNIANIE ====================
  Future<List<String>> getProductSuggestions(String query) async {
    final products = await _productRepo.search(query);
    return products.map((p) => p.name).toList();
  }

  Future<List<ShoppingProduct>> getFrequentProducts() async {
    final list = await _productRepo.getAll();
    print('📋 getFrequentProducts() zwróciło ${list.length} produktów');
    return list;
  }

  // ==================== CRUD ====================
  Future<void> addItem(String name, {String? category, String quantity = "1 szt."}) async {
    final item = ShoppingItem(
      id: _uuid.v4(),
      name: name.trim(),
      category: category,
      quantity: quantity,
      isChecked: false,
      createdAt: DateTime.now(),
    );

    print('📝 Dodaję produkt: ${item.name}');

    await _box.put(item.id, item);
    notifyListeners();
    await _syncToSupabase(item);

    // Zapisz do bazy często kupowanych
    await _productRepo.addOrUpdate(name, category: category);
  }

  Future<void> toggleCheck(String id) async {
    final item = _box.get(id);
    if (item == null) return;
    item.isChecked = !item.isChecked;
    if (item.isChecked) {
      await _productRepo.addOrUpdate(item.name, category: item.category);
    }
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
      final item = _box.get(id);
      final remoteId = item?.supabaseId ?? id;
      await supabase.from('shopping_items').delete().eq('id', remoteId);
    } catch (e) {}
  }

  Future<void> _syncToSupabase(ShoppingItem item) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
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
        'id': item.supabaseId ?? item.id,
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

    // Wszystkie produkty (aktywne + zarchiwizowane) – do wyszukiwarki
  List<ShoppingItem> get allItems => 
      _box.values.toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
}