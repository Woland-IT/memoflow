import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/task_model.dart';
import '../models/task_type.dart';

class TasksProvider with ChangeNotifier {
  final Box<Task> _box = Hive.box<Task>('tasks');

  List<Task> get tasks {
    final list = _box.values.toList();
    list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return list;
  }

  List<Task> get upcomingTasks => tasks.where((t) => 
      !t.isDone && t.dateTime.isAfter(DateTime.now().subtract(const Duration(days: 1)))).toList();

  Future<void> addTask(
  String title, 
  DateTime dateTime, 
  TaskType type, 
  {String? description, String recurrence = "none"}
) async {
  final task = Task(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    title: title.trim(),
    description: description,
    dateTime: dateTime,
    type: type.name,
    recurrence: recurrence,
  );
  await _box.put(task.id, task);
  notifyListeners();
}

  Future<void> toggleDone(String id) async {
    final task = _box.get(id);
    if (task != null) {
      task.isDone = !task.isDone;
      task.updatedAt = DateTime.now();
      await task.save();
      notifyListeners();
    }
  }

  Future<void> deleteTask(String id) async {
    await _box.delete(id);
    notifyListeners();
  }

    // Generowanie powtarzających się zadań
    Future<void> generateRecurringInstances() async {
    print('🔄 generateRecurringInstances - start');
    final now = DateTime.now();
    final allTasks = _box.values.toList();
    int generated = 0;

    for (var task in allTasks) {
      if (task.recurrence == "none" || task.isDone) continue;

      print('🔄 Przetwarzam zadanie: ${task.title} | recurrence: ${task.recurrence} | data: ${task.dateTime}');

      DateTime nextDate = task.dateTime;

      for (int i = 1; i <= 8; i++) {  // więcej instancji do testu
        if (task.recurrence == "weekly") {
          nextDate = nextDate.add(const Duration(days: 7));
        } else if (task.recurrence == "monthly") {
          nextDate = DateTime(nextDate.year, nextDate.month + 1, nextDate.day);
        } else if (task.recurrence == "yearly") {
          nextDate = DateTime(nextDate.year + 1, nextDate.month, nextDate.day);
        } else {
          continue;
        }

        if (nextDate.isBefore(now)) continue;

        final exists = allTasks.any((t) => 
          t.title == task.title && isSameDay(t.dateTime, nextDate));

        if (!exists) {
          final newTask = Task(
            id: '${DateTime.now().millisecondsSinceEpoch}_rec_$i',
            title: task.title,
            description: task.description,
            dateTime: nextDate,
            type: task.type,
            recurrence: "none",
          );
          await _box.put(newTask.id, newTask);
          generated++;
          print('✅ Wygenerowano: ${task.title} na ${nextDate}');
        } else {
          print('⏭ Pominięto (już istnieje): ${task.title} na ${nextDate}');
        }
      }
    }
    print('🔄 generateRecurringInstances - koniec. Wygenerowano: $generated');
    notifyListeners();
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}