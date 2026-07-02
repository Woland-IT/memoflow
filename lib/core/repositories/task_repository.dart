import 'package:hive/hive.dart';
import '../../features/tasks/models/task_model.dart';

class TaskRepository {
  final Box<Task> _box = Hive.box<Task>('tasks');

  List<Task> getAll() => _box.values.toList()..sort((a, b) => a.dateTime.compareTo(b.dateTime));

  Future<void> add(Task task) async {
    await _box.put(task.id, task);
  }

  Future<void> update(Task task) async {
    await _box.put(task.id, task);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}