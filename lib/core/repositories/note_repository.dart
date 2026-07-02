import 'package:hive/hive.dart';
import '../../features/notes/models/note_model.dart';

class NoteRepository {
  final Box<Note> _box = Hive.box<Note>('notes');

  List<Note> getAll() => _box.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Future<void> add(Note note) async {
    await _box.put(note.id, note);
  }

  Future<void> update(Note note) async {
    await _box.put(note.id, note);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  // Supabase methods (później)
  Future<void> syncWithSupabase(String userId) async {
    // TODO: pull + push
  }
}