import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/shopping_product_model.dart';

class ShoppingProductRepository {
  late Box<ShoppingProduct> _box;

  ShoppingProductRepository();

  /// Inicjalizacja boxa – wywołuj w Providerze
  Future<void> init() async {
    if (!Hive.isBoxOpen('shopping_products')) {
      _box = await Hive.openBox<ShoppingProduct>('shopping_products');
    } else {
      _box = Hive.box<ShoppingProduct>('shopping_products');
    }
    print('✅ ShoppingProductRepository init - produktów: ${_box.length}');
  }

  Future<List<ShoppingProduct>> getAll() async {
    await _ensureOpen();
    final list = _box.values.toList();
    print('📦 getAll() - znaleziono ${list.length} produktów');
    return list..sort((a, b) => b.purchaseCount.compareTo(a.purchaseCount));
  }

  Future<void> addOrUpdate(String name, {String? category}) async {
    await _ensureOpen();
    print('🔄 addOrUpdate: $name');

    final lowerName = name.toLowerCase().trim();
    final existing = _box.values.where((p) => 
      p.name.toLowerCase() == lowerName
    ).firstOrNull;

    if (existing != null) {
      existing.purchaseCount++;
      existing.lastPurchased = DateTime.now();
      await existing.save();
      print('✅ Zwiększono licznik dla: $name (${existing.purchaseCount})');
    } else {
      final product = ShoppingProduct.fromName(name, category: category);
      await _box.put(product.id, product);
      print('✅ Dodano nowy produkt: $name');
    }
  }

  Future<List<ShoppingProduct>> search(String query) async {
    await _ensureOpen();
    if (query.trim().isEmpty) {
      return (await getAll()).take(15).toList();
    }

    final lower = query.toLowerCase().trim();
    return _box.values.where((p) => 
      p.name.toLowerCase().contains(lower)
    ).toList();
  }

  Future<void> _ensureOpen() async {
    if (!_box.isOpen) {
      await init();
    }
  }

  /// Debug – przydatne do sprawdzania co jest w boxie
  Future<void> printBoxInfo() async {
    await _ensureOpen();
    print('📊 Box keys: ${_box.keys.length}');
    print('📊 Box values: ${_box.values.map((p) => "${p.name} (${p.purchaseCount})").toList()}');
  }

  /// Opcjonalnie - czyszczenie historii (do testów)
  Future<void> clear() async {
    await _ensureOpen();
    await _box.clear();
    print('🗑️ Box shopping_products wyczyszczony');
  }
}