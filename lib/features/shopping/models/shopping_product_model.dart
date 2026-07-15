import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';   // ← DODAJ TĘ LINIĘ
part 'shopping_product_model.g.dart';

@HiveType(typeId: 3)
class ShoppingProduct extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? category;

  @HiveField(3)
  int purchaseCount;

  @HiveField(4)
  DateTime lastPurchased;

  ShoppingProduct({
    required this.id,
    required this.name,
    this.category,
    this.purchaseCount = 1,
    required this.lastPurchased,
  });

  factory ShoppingProduct.fromName(String name, {String? category}) {
    return ShoppingProduct(
      id: const Uuid().v4(), // lepszy unikalny ID
      name: name.trim(),
      category: category,
      purchaseCount: 1,
      lastPurchased: DateTime.now(),
    );
  }

}