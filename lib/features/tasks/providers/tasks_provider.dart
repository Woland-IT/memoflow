import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';
import '../models/task_type.dart';

class TasksProvider with ChangeNotifier {
  final Box<Task> _box = Hive.box<Task>('tasks');
  final supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  TasksProvider() {
    _init();
  }

  Future<void> _init() async {
    await loadFromSupabase(); // ładuje dane z Supabase przy starcie
  }

  List<Task> get tasks {
    final list = _box.values.toList();
    list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return list;
  }

  // ==================== NADCHODZĄCE ZDARZENIA ====================
  List<Task> get upcomingTasks {
    final now = DateTime.now();
    final List<Task> allInstances = [];

    for (var task in tasks) {
      if (task.isDone) continue;

      final instances = getRecurringInstances(task, upTo: now.add(const Duration(days: 90)));
      allInstances.addAll(instances.where((t) => t.dateTime.isAfter(now)));
    }

    allInstances.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return allInstances.take(50).toList();
  }

  // ==================== ZDARZENIA W DANYM DNIU ====================
  List<Task> getTasksForDay(DateTime date) {
    final List<Task> dayTasks = [];

    for (var task in tasks) {
      final instances = getRecurringInstances(task, upTo: date.add(const Duration(days: 1)));
      dayTasks.addAll(
        instances.where((t) =>
            t.dateTime.year == date.year &&
            t.dateTime.month == date.month &&
            t.dateTime.day == date.day)
      );
    }

    dayTasks.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return dayTasks;
  }

  // ==================== GENEROWANIE POWTARZALNYCH ====================
  List<Task> getRecurringInstances(Task task, {DateTime? upTo}) {
    final List<Task> instances = [];
    if (task.recurrence == "none") return [task];

    DateTime current = task.dateTime;
    final endDate = upTo ?? DateTime.now().add(const Duration(days: 365));

    while (current.isBefore(endDate)) {
      instances.add(
        Task(
          id: '${task.id}_${current.millisecondsSinceEpoch}',
          title: task.title,
          description: task.description,
          dateTime: current,
          type: task.type,
          recurrence: task.recurrence,
          isDone: task.isDone,
        ),
      );

      if (task.recurrence == "weekly") {
        current = current.add(const Duration(days: 7));
      } else if (task.recurrence == "monthly") {
        current = DateTime(current.year, current.month + 1, current.day);
      } else if (task.recurrence == "yearly") {
        current = DateTime(current.year + 1, current.month, current.day);
      } else {
        break;
      }
    }
    return instances;
  }

  // ==================== CRUD ====================
  Future<void> addTask(
    String title, 
    DateTime dateTime, 
    TaskType type, 
    {String? description, String recurrence = "none"}
  ) async {
    final task = Task(
      id: _uuid.v4(),
      title: title.trim(),
      description: description,
      dateTime: dateTime,
      type: type.name,
      isDone: false,
      recurrence: recurrence,
    );

    await _box.put(task.id, task);
    notifyListeners();
    await _syncToSupabase(task);
  }

  Future<void> toggleDone(String id) async {
    final task = _box.get(id);
    if (task == null) return;

    task.isDone = !task.isDone;
    await task.save();
    notifyListeners();
    await _syncToSupabase(task);
  }

  Future<void> deleteTask(String id) async {
    await _box.delete(id);
    notifyListeners();

    try {
      await supabase.from('tasks').delete().eq('id', id);
    } catch (e) {
      print('Błąd usuwania z Supabase: $e');
    }
  }

  Future<void> _syncToSupabase(Task task) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase.from('tasks').upsert({
        'id': task.id,
        'user_id': user.id,
        'title': task.title,
        'description': task.description,
        'is_completed': task.isDone,
        'due_date': task.dateTime.toIso8601String(),
        'recurring': task.recurrence,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');
    } catch (e) {
      print('❌ Błąd sync: $e');
    }
  }

  Future<void> loadFromSupabase() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await supabase
          .from('tasks')
          .select()
          .eq('user_id', user.id);

      for (var json in response) {
        final task = Task.fromJson(json);
        await _box.put(task.id, task);
      }
      notifyListeners();
      print('✅ Zadania załadowane z Supabase');
    } catch (e) {
      print('❌ Błąd pobierania z Supabase: $e');
    }
  }
}