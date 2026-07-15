import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

part 'task_model.g.dart';

@HiveType(typeId: 1)
class Task extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final DateTime dateTime;

  @HiveField(4)
  final String type;           // np. "birthday", "meeting"

  @HiveField(5)
  final String recurrence;     // "none", "weekly", "monthly", "yearly"

  @HiveField(6)
  bool isDone;

  @HiveField(7)
  DateTime? updatedAt;

  @HiveField(8)
  String? supabaseId;           // czysty UUID z Supabase

  Task({
    String? id,
    required this.title,
    this.description,
    required this.dateTime,
    required this.type,
    this.recurrence = 'none',
    this.isDone = false,
    this.updatedAt,
    this.supabaseId,
  }) : id = id ?? const Uuid().v4() + '_' + DateTime.now().millisecondsSinceEpoch.toString();

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      supabaseId: json['id']?.toString(), // czysty UUID z Supabase
      id: json['id']?.toString() ?? const Uuid().v4() + '_' + DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title']?.toString() ?? 'Brak tytułu',
      description: json['description']?.toString(),
      dateTime: json['due_date'] != null 
          ? DateTime.tryParse(json['due_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      type: json['type']?.toString() ?? 'other',
      recurrence: json['recurring']?.toString() ?? json['recurrence']?.toString() ?? 'none',
      isDone: json['is_completed'] == true || json['is_done'] == true,
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at'].toString()) 
          : null,
    );
  }

  Map<String, dynamic> toJson(String userId) {
    return {
      'id': supabaseId ?? id.split('_').first, // używaj supabaseId jeśli istnieje
      'user_id': userId,
      'title': title,
      'description': description,
      'due_date': dateTime.toIso8601String(),
      'type': type,
      'recurring': recurrence,
      'is_completed': isDone,
      'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
    };
  }
}