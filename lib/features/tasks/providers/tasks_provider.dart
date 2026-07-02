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
    // task.updatedAt = DateTime.now(); // jeśli nie ma pola, zakomentuj
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
        'created_at': DateTime.now().toIso8601String(),   // używamy bieżącej daty
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');

      print('✅ Zadanie zsynchronizowane');
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

      for (var json in response) {
        final task = Task.fromJson(json);
        await _box.put(task.id, task);
      }
      notifyListeners();
      print('✅ Pobrano zadania z Supabase');
    } catch (e) {
      print('❌ Błąd pobierania zadań: $e');
    }
  }
}