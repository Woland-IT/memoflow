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
  final String type;

  @HiveField(5)
  final String recurrence;

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

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        dateTime: DateTime.parse(json['date_time']),
        type: json['type'],
        recurrence: json['recurrence'] ?? 'none',
        isDone: json['is_done'] ?? false,
        updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      );

  Map<String, dynamic> toJson(String userId) => {
        'id': id,
        'user_id': userId,
        'title': title,
        'description': description,
        'date_time': dateTime.toIso8601String(),
        'type': type,
        'recurrence': recurrence,
        'is_done': isDone,
        'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
      };
}