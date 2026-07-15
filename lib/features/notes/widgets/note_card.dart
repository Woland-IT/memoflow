import 'package:flutter/material.dart';
import '../models/note_model.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onArchive;   // ← NOWY parametr

  const NoteCard({
    super.key,
    required this.note,
    required this.onEdit,
    required this.onDelete,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: note.isArchived ? Colors.grey[200] : null, // lekkie wyróżnienie archiwum
      child: ListTile(
        title: Text(
          note.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: note.isArchived ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          note.content.length > 100 
              ? '${note.content.substring(0, 100)}...' 
              : note.content,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: onEdit,
            ),
            IconButton(
              icon: Icon(
                note.isArchived ? Icons.unarchive : Icons.archive_outlined,
                color: note.isArchived ? Colors.green : Colors.orange,
              ),
              onPressed: onArchive,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}