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
    await loadFromSupabase();
  }

  List<Task> get tasks {
    final list = _box.values.toList();
    list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return list;
  }

  // ==================== NADCHODZĄCE ZDARZENIA (OPTIMIZACJA) ====================
  List<Task> get upcomingTasks {
    final now = DateTime.now();
    final List<Task> upcoming = [];

    for (var task in tasks) {
      if (task.isDone) continue;

      if (task.recurrence == "none") {
        if (task.dateTime.isAfter(now)) {
          upcoming.add(task);
        }
      } else {
        // Dla powtarzalnych – tylko najbliższe wystąpienie
        final next = _getNextOccurrence(task, now);
        if (next != null && next.isAfter(now)) {
          upcoming.add(task.copyWith(nextOccurrence: next));
        }
      }
    }

    upcoming.sort((a, b) => a.nextOccurrence?.compareTo(b.nextOccurrence ?? a.dateTime) ?? 
                           a.dateTime.compareTo(b.dateTime));
    return upcoming.take(30).toList(); // ograniczenie
  }

  // Pomocnicza metoda – oblicza najbliższe przyszłe wystąpienie
    DateTime? _getNextOccurrence(Task task, DateTime from) {
    if (task.recurrence == "none") return task.dateTime;

    DateTime current = task.dateTime;

    // Jeśli data bazowa jest w przeszłości, przesuń ją do przyszłości
    while (current.isBefore(from) && current.year < from.year + 10) {
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

    return current;
  }
  // ==================== ZDARZENIA W DANYM DNIU ====================
  List<Task> getTasksForDay(DateTime date) {
    final List<Task> dayTasks = [];
    final startOfDay = DateTime(date.year, date.month, date.day);

    for (var task in tasks) {
      if (task.recurrence == "none") {
        if (_isSameDay(task.dateTime, date)) dayTasks.add(task);
      } else {
        final instances = _getRecurringInstancesForDay(task, startOfDay);
        dayTasks.addAll(instances);
      }
    }

    dayTasks.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return dayTasks;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<Task> _getRecurringInstancesForDay(Task task, DateTime day) {
    // uproszczone – można rozwinąć później
    final next = _getNextOccurrence(task, day);
    if (next != null && _isSameDay(next, day)) {
      return [task.copyWith(dateTime: next, nextOccurrence: next)];
    }
    return [];
  }

  // ==================== CRUD ====================
    Future<void> addTask(
    String title, 
    DateTime dateTime, 
    TaskType type, 
    {String? description, String recurrence = "none"}
  ) async {
    final task = Task(
      title: title.trim(),
      description: description,
      dateTime: dateTime,
      type: type.name,
      recurrence: recurrence,
      isDone: false,
    );

    print('📝 DODAWANIE: ${task.title} | Typ: ${task.type} | Recurrence: ${task.recurrence}');

    await _box.put(task.id, task);
    notifyListeners();
    await _syncToSupabase(task);
  }

Future<void> updateTask(Task updatedTask) async {
    print('🔄 AKTUALIZACJA: ${updatedTask.title} | Typ: ${updatedTask.type} | Recurrence: ${updatedTask.recurrence}');

    await _box.put(updatedTask.id, updatedTask);
    notifyListeners();
    await _syncToSupabase(updatedTask);
  }
  Future<void> toggleDone(String id) async {
    final task = _box.get(id);
    if (task == null) return;

    final updated = task.copyWith(isDone: !task.isDone);
    await _box.put(id, updated);
    notifyListeners();
    await _syncToSupabase(updated);
  }

  Future<void> deleteTask(String id) async {
    await _box.delete(id);
    notifyListeners();

    try {
      final task = _box.get(id); // na wszelki wypadek
      final remoteId = task?.supabaseId ?? id;
      await supabase.from('tasks').delete().eq('id', remoteId);
    } catch (e) {
      print('Błąd usuwania: $e');
    }
  }

  Future<void> _syncToSupabase(Task task) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase.from('tasks').upsert({
        'id': task.supabaseId ?? task.id.split('_').first,
        'user_id': user.id,
        'title': task.title,
        'description': task.description,
        'type': task.type,                    // ← DODANE
        'is_completed': task.isDone,
        'due_date': task.dateTime.toIso8601String(),
        'recurring': task.recurrence,
        'next_occurrence': task.nextOccurrence?.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');

      print('✅ Zadanie zsynchronizowane z Supabase: ${task.title}');
    } catch (e) {
      print('❌ Błąd sync zadania: $e');
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

      print('📥 POBRANO ${response.length} zadań z Supabase');

      for (var json in response) {
        final task = Task.fromJson(json);
        print('   → Załadowano: ${task.title} | Typ: ${task.type}');
        await _box.put(task.id, task);
      }
      notifyListeners();
    } catch (e) {
      print('❌ Błąd pobierania: $e');
    }
  }

  // Publiczna metoda do obliczania następnego wystąpienia
  DateTime getNextOccurrence(Task task) {
    final now = DateTime.now();
    if (task.recurrence == "none") return task.dateTime;

    DateTime current = task.dateTime;

    while (current.isBefore(now) && current.year < now.year + 10) {
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
    return current;
  }
}