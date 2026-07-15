import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/notes_provider.dart';
import '../widgets/note_card.dart';
import '../models/note_model.dart';   // ← upewnij się, że model ma pole isArchived

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NotesProvider>(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notatki'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Aktywne'),
              Tab(text: 'Archiwum'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Zakładka 1: Aktywne notatki
            _buildNotesList(provider, false),

            // Zakładka 2: Archiwum
            _buildNotesList(provider, true),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddNoteDialog(context, provider),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildNotesList(NotesProvider provider, bool isArchived) {
    final filteredNotes = provider.notes
        .where((note) => note.isArchived == isArchived)
        .toList();

    if (filteredNotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isArchived ? Icons.archive_outlined : Icons.note_alt_outlined,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              isArchived ? 'Brak archiwalnych notatek' : 'Brak notatek',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredNotes.length,
      itemBuilder: (context, index) {
        final note = filteredNotes[index];
        return NoteCard(
          note: note,
          onEdit: () => _showEditNoteDialog(context, provider, note),
          onDelete: () => provider.deleteNote(note.id),
          // Dodajemy akcję archiwizacji (będzie działać po dodaniu metody w providerze)
          onArchive: () => provider.toggleArchive(note.id),
        );
      },
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
            ),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: 'Treść'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
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
            child: const Text('Dodaj'),
          ),
        ],
      ),
    );
  }

  void _showEditNoteDialog(
    BuildContext context,
    NotesProvider provider,
    Note note, // ← zmień na NoteModel jeśli masz inną nazwę klasy
  ) {
    final titleController = TextEditingController(text: note.title);
    final contentController = TextEditingController(text: note.content);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edytuj notatkę'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Tytuł'),
            ),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: 'Treść'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.updateNote(
                note.id,
                titleController.text,
                contentController.text,
              );
              Navigator.pop(context);
            },
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );
  }
}