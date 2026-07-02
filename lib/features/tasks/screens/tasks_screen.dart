import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/task_model.dart';
import '../models/task_type.dart';
import '../providers/tasks_provider.dart';


class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TasksProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terminarz'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Nadchodzące'),
            Tab(text: 'Rocznice'),
            Tab(text: 'Zarchiwizowane'),
            Tab(text: 'Kalendarz'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUpcomingTab(provider),
          _buildAnniversariesTab(provider),
          _buildArchivedTab(provider),
          _buildCalendarTab(provider),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context, provider),
        child: const Icon(Icons.add),
      ),
    );
  }

  // ==================== Zakładki ====================

  Widget _buildUpcomingTab(TasksProvider provider) {
    final tasks = provider.upcomingTasks;
    return tasks.isEmpty
        ? const Center(child: Text('Brak nadchodzących wydarzeń w tym dniu'))
        : ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return _buildTaskCard(task, provider);
            },
          );
  }

    Widget _buildAnniversariesTab(TasksProvider provider) {
    final anniversaries = provider.tasks.where((t) => 
      t.type == 'birthday' || t.type == 'nameDay' || t.type == 'deathAnniversary'
    ).toList();

    return anniversaries.isEmpty
        ? const Center(child: Text('Brak rocznic'))
        : ListView.builder(
            itemCount: anniversaries.length,
            itemBuilder: (context, index) {
              final task = anniversaries[index];
              return _buildTaskCard(task, provider);
            },
          );
  }

     Widget _buildArchivedTab(TasksProvider provider) {
    final archived = provider.tasks.where((t) => t.isDone).toList(); // tymczasowo używamy isDone jako archiwum
    return archived.isEmpty
        ? const Center(child: Text('Brak zarchiwizowanych wydarzeń'))
        : ListView.builder(
            itemCount: archived.length,
            itemBuilder: (context, index) {
              final task = archived[index];
              return _buildTaskCard(task, provider, isArchived: true);
            },
          );
  }

   Widget _buildCalendarTab(TasksProvider provider) {
    return Column(
      children: [
        // Kalendarz
                TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2035, 12, 31),
          focusedDay: _selectedDate,
          selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() => _selectedDate = selectedDay);
          },
          eventLoader: (day) => provider.getTasksForDay(day),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              if (events.isNotEmpty) {
                return Positioned(
                  right: 6,
                  bottom: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${events.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                );
              }
              return null;
            },
          ),
          calendarStyle: const CalendarStyle(
            markersAlignment: Alignment.bottomRight,
            todayDecoration: BoxDecoration(
              color: Colors.blueAccent,
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),

        const Divider(),

        // Wydarzenia wybranego dnia
        Expanded(
          child: _buildDayEvents(provider),
        ),
      ],
    );
  }



  Widget _buildDayEvents(TasksProvider provider) {
    final dayTasks = provider.getTasksForDay(_selectedDate);
    return dayTasks.isEmpty
        ? const Center(child: Text('Brak wydarzeń w tym dniu'))
        : ListView.builder(
            itemCount: dayTasks.length,
            itemBuilder: (context, index) {
              final task = dayTasks[index];
              return _buildTaskCard(task, provider);
            },
          );
  }

  // ==================== Karta zadania ====================

    Widget _buildTaskCard(Task task, TasksProvider provider, {bool isArchived = false}) {
    final isOverdue = task.dateTime.isBefore(DateTime.now()) && !task.isDone;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _getTypeColor(task.type).withOpacity(0.2),
          child: Icon(
            _getIconForType(task.type),
            color: _getTypeColor(task.type),
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: task.isDone ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('dd.MM.yyyy • HH:mm').format(task.dateTime),
              style: TextStyle(
                color: isOverdue ? Colors.red : Colors.grey[600],
                fontSize: 13,
              ),
            ),
            if (task.description != null && task.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  task.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
          ],
        ),
        trailing: isArchived
            ? const Icon(Icons.archive, color: Colors.grey)
            : Checkbox(
                value: task.isDone,
                onChanged: (_) => provider.toggleDone(task.id),
                activeColor: Colors.green,
              ),
        onTap: () => _showEditTaskDialog(context, provider, task),
        onLongPress: () => _confirmArchiveOrDelete(context, provider, task),
      ),
    );
  }

    IconData _getIconForType(String typeStr) {
    try {
      final type = TaskType.values.byName(typeStr);
      return type.icon;
    } catch (e) {
      return Icons.event_note; // fallback
    }
  }

  Color _getTypeColor(String typeStr) {
    switch (typeStr) {
      case 'birthday':
      case 'nameDay':
        return Colors.pink;
      case 'meeting':
        return Colors.blue;
      case 'call':
        return Colors.green;
      case 'deathAnniversary':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

    // ==================== Dialog dodawania zadania ====================

    void _showAddTaskDialog(BuildContext context, TasksProvider provider) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    TaskType selectedType = TaskType.other;
    String recurrence = "none";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nowe wydarzenie'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Tytuł'),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Opis'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              ListTile(
                title: Text('Data: ${DateFormat('dd.MM.yyyy').format(selectedDate)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (date != null) {
                    setState(() => selectedDate = date);
                  }
                },
              ),
              ListTile(
                title: Text('Godzina: ${selectedTime.format(context)}'),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (time != null) {
                    setState(() => selectedTime = time);
                  }
                },
              ),
              DropdownButtonFormField<TaskType>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Typ'),
                items: TaskType.values.map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type.displayName),
                )).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => selectedType = value);
                },
              ),
              DropdownButtonFormField<String>(
                value: recurrence,
                decoration: const InputDecoration(labelText: 'Powtarzanie'),
                items: const [
                  DropdownMenuItem(value: "none", child: Text('Jednorazowe')),
                  DropdownMenuItem(value: "weekly", child: Text('Co tydzień')),
                  DropdownMenuItem(value: "monthly", child: Text('Co miesiąc')),
                  DropdownMenuItem(value: "yearly", child: Text('Co rok')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => recurrence = value);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isEmpty) return;

              final dateTime = DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
                selectedTime.hour,
                selectedTime.minute,
              );

              provider.addTask(
                titleController.text,
                dateTime,
                selectedType,
                description: descController.text.isEmpty ? null : descController.text,
                recurrence: recurrence,
              );

              Navigator.pop(context);
            },
            child: const Text('Dodaj'),
          ),
        ],
      ),
    );
  }
    // ==================== Dialog edycji zadania ====================

    void _showEditTaskDialog(BuildContext context, TasksProvider provider, Task task) {
    final titleController = TextEditingController(text: task.title);
    final descController = TextEditingController(text: task.description);
    DateTime selectedDate = task.dateTime;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(task.dateTime);
    TaskType selectedType = TaskType.values.byName(task.type); // dopasowane do String
    String recurrence = task.recurrence;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edytuj wydarzenie'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Tytuł'),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Opis'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              ListTile(
                title: Text('Data: ${DateFormat('dd.MM.yyyy').format(selectedDate)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (date != null) setState(() => selectedDate = date);
                },
              ),
              ListTile(
                title: Text('Godzina: ${selectedTime.format(context)}'),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (time != null) setState(() => selectedTime = time);
                },
              ),
              DropdownButtonFormField<TaskType>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Typ'),
                items: TaskType.values.map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type.displayName),
                )).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => selectedType = value);
                },
              ),
              DropdownButtonFormField<String>(
                value: recurrence,
                decoration: const InputDecoration(labelText: 'Powtarzanie'),
                items: const [
                  DropdownMenuItem(value: "none", child: Text('Jednorazowe')),
                  DropdownMenuItem(value: "weekly", child: Text('Co tydzień')),
                  DropdownMenuItem(value: "monthly", child: Text('Co miesiąc')),
                  DropdownMenuItem(value: "yearly", child: Text('Co rok')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => recurrence = value);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isEmpty) return;

              final dateTime = DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
                selectedTime.hour,
                selectedTime.minute,
              );

              // Na razie aktualizujemy przez delete + add (proste rozwiązanie)
              provider.deleteTask(task.id);
              provider.addTask(
                titleController.text,
                dateTime,
                selectedType,
                description: descController.text.isEmpty ? null : descController.text,
                recurrence: recurrence,
              );

              Navigator.pop(context);
            },
            child: const Text('Zapisz zmiany'),
          ),
        ],
      ),
    );
  }
    // ==================== Potwierdzenie archiwizacji/usunięcia ====================

    void _confirmArchiveOrDelete(BuildContext context, TasksProvider provider, Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Co chcesz zrobić?'),
        content: Text('„${task.title}”'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () {
              // Na razie używamy delete (możesz dodać archiwizację później)
              provider.deleteTask(task.id);
              Navigator.pop(context);
            },
            child: const Text('Usuń', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ewentualne dodatkowe inicjalizacje
  }


}