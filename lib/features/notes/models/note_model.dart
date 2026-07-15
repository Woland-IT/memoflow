import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

part 'note_model.g.dart';

@HiveType(typeId: 0)
class Note extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String content;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final String? category;

  @HiveField(5)
  DateTime? updatedAt;

  @HiveField(6)
  String? supabaseId;           // czysty UUID z Supabase

  Note({
    String? id,
    required this.title,
    required this.content,
    DateTime? createdAt,
    this.category,
    this.updatedAt,
    this.supabaseId,
  })  : id = id ?? const Uuid().v4() + '_' + DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now();

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] ?? const Uuid().v4() + '_' + DateTime.now().millisecondsSinceEpoch.toString(),
      supabaseId: json['id']?.toString(), // czysty UUID
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      category: json['category'],
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson(String userId) {
    return {
      'id': supabaseId ?? id.split('_').first, // używaj supabaseId jeśli istnieje
      'user_id': userId,
      'title': title,
      'content': content,
      'category': category,
      'created_at': createdAt.toIso8601String(),
      'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
    };
  }
}