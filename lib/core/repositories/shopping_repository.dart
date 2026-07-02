import 'package:hive/hive.dart';
import '../../features/shopping/models/shopping_item_model.dart';

class ShoppingRepository {
  final Box<ShoppingItem> _box = Hive.box<ShoppingItem>('shopping_items');

  List<ShoppingItem> getActive() => _box.values.where((i) => !i.isChecked).toList()..sort((a, b) => a.name.compareTo(b.name));

  List<ShoppingItem> getArchived() => _box.values.where((i) => i.isChecked).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Future<void> add(ShoppingItem item) async {
    await _box.put(item.id, item);
  }

  Future<void> update(ShoppingItem item) async {
    await _box.put(item.id, item);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}