import 'package:hive/hive.dart';

part 'shopping_item_model.g.dart';

@HiveType(typeId: 2)
class ShoppingItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? category;

  @HiveField(3)
  final String quantity;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  bool isChecked;

  @HiveField(6)
  DateTime? updatedAt;

  ShoppingItem({
    required this.id,
    required this.name,
    this.category,
    this.quantity = '1 szt.',
    required this.createdAt,
    this.isChecked = false,
    this.updatedAt,
  });

  factory ShoppingItem.fromJson(Map<String, dynamic> json) => ShoppingItem(
        id: json['id'],
        name: json['name'],
        category: json['category'],
        quantity: json['quantity'] ?? '1 szt.',
        createdAt: DateTime.parse(json['created_at']),
        isChecked: json['is_checked'] ?? false,
        updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      );

  Map<String, dynamic> toJson(String userId) => {
        'id': id,
        'user_id': userId,
        'name': name,
        'category': category,
        'quantity': quantity,
        'created_at': createdAt.toIso8601String(),
        'is_checked': isChecked,
        'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
      };
}