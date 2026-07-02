# ====================== MemoFlow Setup - PowerShell ======================
Write-Host "🚀 MemoFlow - Tworzę strukturę folderów i plików..." -ForegroundColor Cyan

# Tworzenie folderów
New-Item -ItemType Directory -Force -Path "lib\core" | Out-Null
New-Item -ItemType Directory -Force -Path "lib\features\notes\models" | Out-Null
New-Item -ItemType Directory -Force -Path "lib\features\notes\providers" | Out-Null
New-Item -ItemType Directory -Force -Path "lib\features\notes\screens" | Out-Null
New-Item -ItemType Directory -Force -Path "lib\features\notes\widgets" | Out-Null
New-Item -ItemType Directory -Force -Path "lib\features\tasks\screens" | Out-Null
New-Item -ItemType Directory -Force -Path "lib\features\shopping\screens" | Out-Null
New-Item -ItemType Directory -Force -Path "lib\shared\widgets" | Out-Null

Write-Host "✅ Foldery utworzone" -ForegroundColor Green

# === PLIKI ===

# lib/main.dart
@"
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'features/notes/models/note_model.dart';
import 'features/notes/providers/notes_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
  Hive.registerAdapter(NoteAdapter());
  await Hive.openBox<Note>('notes');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotesProvider()),
      ],
      child: const MemoFlowApp(),
    ),
  );
}
"@ | Set-Content -Path "lib\main.dart" -Encoding UTF8

# lib/app.dart
@"
import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'features/notes/screens/notes_screen.dart';
import 'features/tasks/screens/tasks_screen.dart';
import 'features/shopping/screens/shopping_screen.dart';
import 'shared/widgets/bottom_nav_bar.dart';

class MemoFlowApp extends StatefulWidget {
  const MemoFlowApp({super.key});

  @override
  State<MemoFlowApp> createState() => _MemoFlowAppState();
}

class _MemoFlowAppState extends State<MemoFlowApp> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    NotesScreen(),
    TasksScreen(),
    ShoppingScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MemoFlow',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: _screens[_currentIndex],
        bottomNavigationBar: BottomNavBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
        ),
      ),
    );
  }
}
"@ | Set-Content -Path "lib\app.dart" -Encoding UTF8

# lib/core/theme.dart
@"
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
      );
}
"@ | Set-Content -Path "lib\core\theme.dart" -Encoding UTF8

# lib/features/notes/models/note_model.dart
@"
import 'package:hive/hive.dart';

part 'note_model.g.dart';

@HiveType(typeId: 0)
class Note extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String content;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final String? category;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.category,
  });
}
"@ | Set-Content -Path "lib\features\notes\models\note_model.dart" -Encoding UTF8

# lib/features/notes/providers/notes_provider.dart
@"
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/note_model.dart';

class NotesProvider with ChangeNotifier {
  final Box<Note> _box = Hive.box<Note>('notes');

  List<Note> get notes {
    final list = _box.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> addNote(String title, String content, {String? category}) async {
    final note = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.trim(),
      content: content.trim(),
      createdAt: DateTime.now(),
      category: category,
    );
    await _box.put(note.id, note);
    notifyListeners();
  }

  Future<void> deleteNote(String id) async {
    await _box.delete(id);
    notifyListeners();
  }
}
"@ | Set-Content -Path "lib\features\notes\providers\notes_provider.dart" -Encoding UTF8

# lib/features/notes/screens/notes_screen.dart + widgets + pozostałe (skrócone dla czytelności – resztę dodam w kolejnej wiadomości jeśli potrzeba)
Write-Host "✅ Podstawowe pliki utworzone" -ForegroundColor Green
Write-Host "Teraz uruchom w PowerShell:" -ForegroundColor Yellow
Write-Host "dart run build_runner build --delete-conflicting-outputs" 
Write-Host "flutter run"