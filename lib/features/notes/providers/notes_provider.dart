import 'package:flutter/material.dart';
import '../../core/repositories/note_repository.dart';
import '../../features/notes/models/note_model.dart';

class NotesProvider with ChangeNotifier {
  final NoteRepository _repository = NoteRepository();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Note> get notes => _repository.getAll();

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
      await _repository.add(note);
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