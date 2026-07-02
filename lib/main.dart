import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';

import 'features/notes/models/note_model.dart';
import 'features/tasks/models/task_model.dart';
import 'features/shopping/models/shopping_item_model.dart';

import 'features/notes/providers/notes_provider.dart';
import 'features/tasks/providers/tasks_provider.dart';
import 'features/shopping/providers/shopping_provider.dart';

import 'core/services/auth_service.dart';
import 'core/services/sync_service.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  // ====================== HIVE ======================
  await Hive.initFlutter();

  Hive.registerAdapter(NoteAdapter());
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(ShoppingItemAdapter());

  // Tymczasowe czyszczenie (usuń po teście)
  // await Hive.deleteBoxFromDisk('tasks');

  await Hive.openBox<Note>('notes');
  await Hive.openBox<Task>('tasks');
  await Hive.openBox<ShoppingItem>('shopping_items');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotesProvider()),
        ChangeNotifierProvider(create: (_) => TasksProvider()),
        ChangeNotifierProvider(create: (_) => ShoppingProvider()),
        ChangeNotifierProvider(create: (_) => AuthService()),      // ← DODAJ
        ChangeNotifierProvider(create: (_) => SyncService()),
      ],
      child: const MemoFlowApp(),
    ),
  );
}

// Globalny klient Supabase (używać w serwisach)
final supabase = Supabase.instance.client;