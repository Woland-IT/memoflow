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
  String? supabaseId;

  @HiveField(7)                    // ← NOWE POLE
  bool isArchived;

  Note({
    String? id,
    required this.title,
    required this.content,
    DateTime? createdAt,
    this.category,
    this.updatedAt,
    this.supabaseId,
    this.isArchived = false,       // ← domyślnie false
  })  : id = id ?? const Uuid().v4() + '_' + DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now();

  // copyWith – bardzo przydatne przy archiwizacji
  Note copyWith({
    String? title,
    String? content,
    String? category,
    DateTime? updatedAt,
    bool? isArchived,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      category: category ?? this.category,
      updatedAt: updatedAt ?? this.updatedAt,
      supabaseId: supabaseId,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] ?? const Uuid().v4() + '_' + DateTime.now().millisecondsSinceEpoch.toString(),
      supabaseId: json['id']?.toString(),
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      category: json['category'],
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      isArchived: json['is_archived'] ?? false,     // ← dodane
    );
  }

  Map<String, dynamic> toJson(String userId) {
    return {
      'id': supabaseId ?? id.split('_').first,
      'user_id': userId,
      'title': title,
      'content': content,
      'category': category,
      'is_archived': isArchived,                    // ← dodane
      'created_at': createdAt.toIso8601String(),
      'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
    };
  }
}