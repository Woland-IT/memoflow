import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/notes/providers/notes_provider.dart';
import '../../features/tasks/providers/tasks_provider.dart';
import '../../features/shopping/providers/shopping_provider.dart';

class SyncService extends ChangeNotifier {
  final supabase = Supabase.instance.client;

  // Prosty status
  bool isSyncing = false;

  Future<void> syncAll({
    required NotesProvider notesProvider,
    required TasksProvider tasksProvider,
    required ShoppingProvider shoppingProvider,
  }) async {
    if (supabase.auth.currentUser == null) return;

    isSyncing = true;
    notifyListeners();

    try {
      // TODO: Na razie placeholder – później pełne push/pull
      await _syncNotes(notesProvider);
      await _syncTasks(tasksProvider);
      await _syncShopping(shoppingProvider);

      print('✅ Sync completed');
    } catch (e) {
      print('❌ Sync error: $e');
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _syncNotes(NotesProvider provider) async {
    // Przykład: pobierz z Supabase i merguj z Hive
    final userId = supabase.auth.currentUser!.id;
    final response = await supabase
        .from('notes')
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false);

    // Tutaj logika mergowania z lokalnym Hive...
    // Na razie zostawiam jako szkielet
  }

  // Podobne metody dla tasks i shopping...
  Future<void> _syncTasks(TasksProvider provider) async { /* ... */ }
  Future<void> _syncShopping(ShoppingProvider provider) async { /* ... */ }
}