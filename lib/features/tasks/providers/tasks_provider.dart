import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/task_model.dart';
import '../models/task_type.dart';

class TasksProvider with ChangeNotifier {
  final Box<Task> _box = Hive.box<Task>('tasks');

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (title.trim().isEmpty) throw Exception('Tytuł zadania nie może być pusty');
      final task = Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title.trim(),
        description: description,
        dateTime: dateTime,
        type: type.name,
        recurrence: recurrence,
      );
      await _box.put(task.id, task);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleDone(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final task = _box.get(id);
      if (task != null) {
        task.isDone = !task.isDone;
        task.updatedAt = DateTime.now();
        await task.save();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteTask(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _box.delete(id);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Generowanie powtarzających się zadań (zostawione z poprawkami)
  Future<void> generateRecurringInstances() async {
    _isLoading = true;
    notifyListeners();
    // ... istniejąca logika ...
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}