import 'package:hive/hive.dart';

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

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.dateTime,
    required this.type,
    this.recurrence = 'none',
    this.isDone = false,
    this.updatedAt,
  });

  // Poprawiony fromJson pod Supabase
  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id']?.toString() ?? '',
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'due_date': dateTime.toIso8601String(),
        'type': type,
        'recurring': recurrence,
        'is_completed': isDone,
        'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
      };
}