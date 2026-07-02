import 'package:hive/hive.dart';
import '../../features/notes/models/note_model.dart';

class NoteRepository {
  final Box<Note> _box = Hive.box<Note>('notes');

  List<Note> getAll() {
    final list = _box.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> add(Note note) async {
    await _box.put(note.id, note);
  }

  Future<void> update(Note note) async {
    await _box.put(note.id, note);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}