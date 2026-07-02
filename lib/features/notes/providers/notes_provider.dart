import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/note_model.dart';

class NotesProvider with ChangeNotifier {
  final Box<Note> _box = Hive.box<Note>('notes');

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Note> get notes {
    final list = _box.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  // Wyszukiwanie
  List<Note> searchNotes(String query) {
    if (query.isEmpty) return notes;
    final lowerQuery = query.toLowerCase();
    return notes.where((note) =>
      note.title.toLowerCase().contains(lowerQuery) ||
      note.content.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  Future<void> addNote(String title, String content, {String? category}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (title.trim().isEmpty) throw Exception('Tytuł nie może być pusty');
      final note = Note(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title.trim(),
        content: content.trim(),
        createdAt: DateTime.now(),
        category: category,
      );
      await _box.put(note.id, note);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateNote(String id, String title, String content, {String? category}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final oldNote = _box.get(id);
      if (oldNote != null && title.trim().isNotEmpty) {
        final updatedNote = Note(
          id: oldNote.id,
          title: title.trim(),
          content: content.trim(),
          createdAt: oldNote.createdAt,
          category: category ?? oldNote.category,
        );
        await _box.put(id, updatedNote);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteNote(String id) async {
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

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}