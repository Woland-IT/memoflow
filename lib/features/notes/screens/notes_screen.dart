import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note_model.dart';
import '../providers/notes_provider.dart';
import '../widgets/note_card.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotesProvider>();
    final filteredNotes = provider.searchNotes(_searchQuery);

    return Scaffold(
      appBar: AppBar(title: const Text('Notatki')),
      body: Column(
        children: [
          // Wyszukiwanie
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Szukaj notatek...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          Expanded(
            child: filteredNotes.isEmpty
                ? const Center(child: Text('Brak notatek pasujących do wyszukiwania'))
                : ListView.builder(
                    itemCount: filteredNotes.length,
                    itemBuilder: (context, index) {
                      final note = filteredNotes[index];
                      return NoteCard(
                        note: note,
                        onEdit: () => _showEditNoteDialog(context, provider, note),
                        onDelete: () => _confirmDelete(context, provider, note.id),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddNoteDialog(context, provider),
        child: const Icon(Icons.add),
      ),
    );
  }

  // Dodawanie
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
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Tytuł')),
            const SizedBox(height: 12),
            TextField(controller: contentController, decoration: const InputDecoration(labelText: 'Treść'), maxLines: 5),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Anuluj')),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                provider.addNote(titleController.text, contentController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );
  }

  // Edycja
  void _showEditNoteDialog(BuildContext context, NotesProvider provider, Note note) {
    final titleController = TextEditingController(text: note.title);
    final contentController = TextEditingController(text: note.content);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edytuj notatkę'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Tytuł')),
            const SizedBox(height: 12),
            TextField(controller: contentController, decoration: const InputDecoration(labelText: 'Treść'), maxLines: 5),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Anuluj')),
          ElevatedButton(
            onPressed: () {
              provider.updateNote(note.id, titleController.text, contentController.text);
              Navigator.pop(context);
            },
            child: const Text('Zapisz zmiany'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, NotesProvider provider, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usunąć notatkę?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Anuluj')),
          TextButton(
            onPressed: () {
              provider.deleteNote(id);
              Navigator.pop(context);
            },
            child: const Text('Usuń', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}