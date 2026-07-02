import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/notes/providers/notes_provider.dart';
import '../../features/tasks/providers/tasks_provider.dart';
import '../../features/shopping/providers/shopping_provider.dart';
import '../../features/notes/models/note_model.dart';
import '../../features/tasks/models/task_model.dart';
import '../../features/shopping/models/shopping_item_model.dart';

class SyncService extends ChangeNotifier {
  final supabase = Supabase.instance.client;

  bool isSyncing = false;
  String? lastSyncError;

  Future<void> syncAll({
    required NotesProvider notesProvider,
    required TasksProvider tasksProvider,
    required ShoppingProvider shoppingProvider,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    isSyncing = true;
    lastSyncError = null;
    notifyListeners();

    try {
      await _pullNotes(notesProvider, user.id);
      await _pullTasks(tasksProvider, user.id);
      await _pullShopping(shoppingProvider, user.id);

      // TODO: push local changes
      await _pushLocalChanges(notesProvider, tasksProvider, shoppingProvider, user.id);

      print('✅ Pełna synchronizacja zakończona');
    } catch (e) {
      lastSyncError = e.toString();
      print('❌ Sync error: $e');
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _pullNotes(NotesProvider provider, String userId) async {
    final response = await supabase
        .from('notes')
        .select()
        .eq('user_id', userId);

    // Merguj z lokalnym Hive (prosty przykład – w produkcji porównuj timestampy)
    for (var item in response) {
      final note = Note.fromJson(item); // dodaj fromJson do modelu
      // provider._box.put... logika mergowania
    }
  }

  Future<void> _pullTasks(TasksProvider provider, String userId) async { /* analogicznie */ }
  Future<void> _pullShopping(ShoppingProvider provider, String userId) async { /* analogicznie */ }

  Future<void> _pushLocalChanges(
    NotesProvider notesP,
    TasksProvider tasksP,
    ShoppingProvider shoppingP,
    String userId,
  ) async {
    // Przykład push notes
    // for each local change -> supabase.from('notes').upsert(...)
  }

  void clearError() {
    lastSyncError = null;
    notifyListeners();
  }
}