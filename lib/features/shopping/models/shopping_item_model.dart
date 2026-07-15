import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

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

  @HiveField(7)
  String? supabaseId;           // czysty UUID z Supabase

  ShoppingItem({
    String? id,
    required this.name,
    this.category,
    this.quantity = '1 szt.',
    DateTime? createdAt,
    this.isChecked = false,
    this.updatedAt,
    this.supabaseId,
  }) : id = id ?? const Uuid().v4() + '_' + DateTime.now().millisecondsSinceEpoch.toString(),
       createdAt = createdAt ?? DateTime.now();

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      supabaseId: json['id']?.toString(), // czysty UUID z Supabase
      id: json['id']?.toString() ?? const Uuid().v4() + '_' + DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] ?? '',
      category: json['category'],
      quantity: json['quantity']?.toString() ?? '1 szt.',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      isChecked: json['is_checked'] == true,
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson(String userId) {
    return {
      'id': supabaseId ?? id.split('_').first, // używaj supabaseId jeśli istnieje
      'user_id': userId,
      'name': name,
      'category': category,
      'quantity': quantity,
      'created_at': createdAt.toIso8601String(),
      'is_checked': isChecked,
      'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
    };
  }
}