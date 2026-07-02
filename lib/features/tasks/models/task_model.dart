import 'package:hive/hive.dart';
import 'task_type.dart';

part 'task_model.g.dart';

@HiveType(typeId: 1)
class Task extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  DateTime dateTime;

  @HiveField(4)
  String type;  // birthday, meeting itd.

  @HiveField(5)
  bool isDone;

  @HiveField(6)
  DateTime? updatedAt;

  @HiveField(7)
  String recurrence;   // "none", "weekly" itd.

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.dateTime,
    required this.type,
    this.isDone = false,
    this.updatedAt,
    this.recurrence = "none",
  }) {
    updatedAt ??= DateTime.now();
  }
}