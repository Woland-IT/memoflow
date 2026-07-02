import 'package:hive/hive.dart';

part 'shopping_item_model.g.dart';

@HiveType(typeId: 2)
class ShoppingItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? category;

  @HiveField(3)
  String quantity;        // np. "2 szt.", "300g", "1 l", "1 opak."

  @HiveField(4)
  bool isChecked;

  @HiveField(5)
  DateTime createdAt;

  ShoppingItem({
    required this.id,
    required this.name,
    this.category,
    this.quantity = "1 szt.",
    this.isChecked = false,
    required this.createdAt,
  });
}