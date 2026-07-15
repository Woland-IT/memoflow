import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/note_model.dart';

class NotesProvider with ChangeNotifier {
  final Box<Note> _box = Hive.box<Note>('notes');
  final supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  List<Note> get notes {
    final list = _box.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<Note> searchNotes(String query) {
    if (query.isEmpty) return notes;
    final lowerQuery = query.toLowerCase();
    return notes.where((note) =>
      note.title.toLowerCase().contains(lowerQuery) ||
      note.content.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  // ==================== DODAWANIE ====================
  Future<void> addNote(String title, String content, {String? category}) async {
    final note = Note(
      id: _uuid.v4(),
      title: title.trim(),
      content: content.trim(),
      createdAt: DateTime.now(),
      category: category,
    );

    await _box.put(note.id, note);
    notifyListeners();
    await _syncToSupabase(note);
  }

  // ==================== EDYCJA ====================
  Future<void> updateNote(String id, String title, String content, {String? category}) async {
    final oldNote = _box.get(id);
    if (oldNote == null) return;

    final updatedNote = Note(
      id: oldNote.id,
      title: title.trim(),
      content: content.trim(),
      createdAt: oldNote.createdAt,
      category: category ?? oldNote.category,
      updatedAt: DateTime.now(),
    );

    await _box.put(id, updatedNote);
    notifyListeners();
    await _syncToSupabase(updatedNote);
  }

  // ==================== USUWANIE ====================
  Future<void> deleteNote(String id) async {
    final note = _box.get(id);
    await _box.delete(id);
    notifyListeners();

    try {
      // Używaj supabaseId jeśli dostępny, inaczej użyj id
      final remoteId = note?.supabaseId ?? id;
      await supabase.from('notes').delete().eq('id', remoteId);
    } catch (e) {
      print('Błąd usuwania z Supabase: $e');
    }
  }

  // ==================== SYNCHRONIZACJA ====================
  Future<void> _syncToSupabase(Note note) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      print('⚠️ Brak zalogowanego użytkownika - pomijam sync');
      return;
    }

    try {
      await supabase.from('notes').upsert({
        'id': note.supabaseId ?? note.id,  // Używaj supabaseId jeśli dostępny
        'user_id': user.id,
        'title': note.title,
        'content': note.content,
        'category': note.category,
        'created_at': note.createdAt.toIso8601String(),
        'updated_at': (note.updatedAt ?? DateTime.now()).toIso8601String(),
      }, onConflict: 'id');

      print('✅ Notatka zsynchronizowana z Supabase');
    } catch (e) {
      print('❌ Błąd sync notatki: $e');
    }
  }

  // ==================== WCZYTANIE Z SUPABASE ====================
  Future<void> loadFromSupabase() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await supabase
          .from('notes')
          .select()
          .eq('user_id', user.id);

      for (var json in response) {
        final note = Note.fromJson(json);
        await _box.put(note.id, note);
      }
      notifyListeners();
      print('✅ Pobrano notatki z Supabase');
    } catch (e) {
      print('❌ Błąd pobierania notatek z Supabase: $e');
    }
  }
}