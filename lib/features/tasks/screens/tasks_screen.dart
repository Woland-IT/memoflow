import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tasks_provider.dart';

// Podobnie jak NotesScreen - dodano isLoading
// ... (skrócone dla przykładu)
class TasksScreen extends StatelessWidget {
  // ...
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TasksProvider>(context);
    return Scaffold(
      body: provider.isLoading ? const Center(child: CircularProgressIndicator()) : /* lista zadań */,
      // ...
    );
  }
}