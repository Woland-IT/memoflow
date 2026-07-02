#!/bin/bash
set -e

echo "📁 Tworzę strukturę folderów MemoFlow..."

mkdir -p lib/core \
  lib/features/notes/models \
  lib/features/notes/providers \
  lib/features/notes/screens \
  lib/features/notes/widgets \
  lib/features/tasks/screens \
  lib/features/shopping/screens \
  lib/shared/widgets

echo "📝 Tworzę pliki z zawartością..."

# main.dart
cat << 'EOF' > lib/main.dart
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
EOF

# app.dart
cat << 'EOF' > lib/app.dart
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
EOF

# core/theme.dart
cat << 'EOF' > lib/core/theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
      );
}
EOF

# note_model.dart
cat << 'EOF' > lib/features/notes/models/note_model.dart
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
EOF

# notes_provider.dart
cat << 'EOF' > lib/features/notes/providers/notes_provider.dart
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
EOF

# notes_screen.dart
cat << 'EOF' > lib/features/notes/screens/notes_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notes_provider.dart';
import '../widgets/note_card.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotesProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Notatki')),
      body: provider.notes.isEmpty
          ? const Center(child: Text('Brak notatek.\nDodaj pierwszą!'))
          : ListView.builder(
              itemCount: provider.notes.length,
              itemBuilder: (context, index) {
                final note = provider.notes[index];
                return NoteCard(
                  note: note,
                  onDelete: () => provider.deleteNote(note.id),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddNoteDialog(context, provider),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context, NotesProvider provider) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nowa notatka'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Tytuł'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: 'Treść'),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Anuluj')),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                provider.addNote(
                  titleController.text,
                  contentController.text,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );
  }
}
EOF

# note_card.dart
cat << 'EOF' > lib/features/notes/widgets/note_card.dart
import 'package:flutter/material.dart';
import '../models/note_model.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onDelete;

  const NoteCard({super.key, required this.note, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          note.content.length > 80 ? '${note.content.substring(0, 80)}...' : note.content,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
EOF

# tasks_screen.dart (placeholder)
cat << 'EOF' > lib/features/tasks/screens/tasks_screen.dart
import 'package:flutter/material.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terminarz')),
      body: const Center(
        child: Text('Terminarz + przypomnienia\nWkrótce w MemoFlow! 📅', textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
EOF

# shopping_screen.dart (placeholder)
cat << 'EOF' > lib/features/shopping/screens/shopping_screen.dart
import 'package:flutter/material.dart';

class ShoppingScreen extends StatelessWidget {
  const ShoppingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Listy zakupów')),
      body: const Center(
        child: Text('Listy zakupów z checkboxami\nWkrótce w MemoFlow! 🛒', textAlign: TextAlign.center, style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
EOF

# bottom_nav_bar.dart
cat << 'EOF' > lib/shared/widgets/bottom_nav_bar.dart
import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.note_alt_outlined), label: 'Notatki'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: 'Terminarz'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: 'Zakupy'),
      ],
    );
  }
}
EOF

echo "✅ Struktura i pliki utworzone!"
echo "Teraz uruchom:"
echo "dart run build_runner build --delete-conflicting-outputs"
echo "flutter run"