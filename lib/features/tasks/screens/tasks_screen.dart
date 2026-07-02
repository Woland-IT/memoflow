mport 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/task_model.dart';
import '../providers/tasks_provider.dart';
import '../models/task_type.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

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
    final provider = context.watch<TasksProvider>();

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
          _buildRecurringTab(provider),
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

  Widget _buildRecurringTab(TasksProvider provider) {
    final recurring = provider.tasks.where((t) =>
      (t.type == TaskType.birthday.name || t.type == TaskType.nameDay.name || t.type == TaskType.deathAnniversary.name) && !t.isDone).toList();
    return _buildTaskList(recurring, provider);
  }

  Widget _buildMeetingsTab(TasksProvider provider) {
    final meetings = provider.tasks.where((t) =>
      (t.type == TaskType.meeting.name || t.type == TaskType.call.name || t.type == TaskType.other.name) && !t.isDone).toList();
    return _buildTaskList(meetings, provider);
  }

  Widget _buildArchivedTab(TasksProvider provider) {
    final archived = provider.tasks.where((t) => t.isDone).toList();
    return _buildTaskList(archived, provider, showCheckbox: false);
  }

  Widget _buildCalendarTab(TasksProvider provider) {
    final events = _getEventsForDay(provider, _selectedDay ?? _focusedDay);

    return Column(
      children: [
        TableCalendar<Task>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          eventLoader: (day) => _getEventsForDay(provider, day),
          calendarStyle: const CalendarStyle(
            markersAlignment: Alignment.bottomRight,
          ),
        ),
        const Divider(),
        Expanded(
          child: events.isEmpty
              ? const Center(child: Text('Brak wydarzeń w tym dniu'))
              : ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final task = events[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: Icon(_getIconForType(task.type)),
                        title: Text(task.title),
                        subtitle: Text(DateFormat('HH:mm').format(task.dateTime)),
                        trailing: task.isDone ? const Icon(Icons.check_circle, color: Colors.green) : null,
                        onTap: () => _showEditTaskDialog(context, provider, task),
                        onLongPress: () => _confirmArchiveOrDelete(context, provider, task),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  List<Task> _getEventsForDay(TasksProvider provider, DateTime day) {
    return provider.tasks.where((task) => isSameDay(task.dateTime, day)).toList();
  }

  Widget _buildTaskList(List<Task> tasks, TasksProvider provider, {bool showCheckbox = true}) {
    if (tasks.isEmpty) {
      return const Center(child: Text('Brak wydarzeń w tej kategorii'));
    }

    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(task.dateTime);
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: ListTile(
            leading: Icon(_getIconForType(task.type), color: _getTypeColorForString(task.type)),
            title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateStr),
                if (task.description != null && task.description!.isNotEmpty)
                  Text(task.description!, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
            trailing: showCheckbox
                ? Checkbox(value: task.isDone, onChanged: (_) => provider.toggleDone(task.id))
                : null,
            onTap: () => _showEditTaskDialog(context, provider, task),
            onLongPress: () => _confirmArchiveOrDelete(context, provider, task),
          ),
        );
      },
    );
  }

  Color _getTypeColor(TaskType type) {
    switch (type) {
      case TaskType.birthday:
        return Colors.pink;
      case TaskType.nameDay:
        return Colors.orange;
      case TaskType.deathAnniversary:
        return Colors.grey;
      case TaskType.meeting:
        return Colors.blue;
      case TaskType.call:
        return Colors.green;
      default:
        return Colors.teal;
    }
  }

  void _showAddTaskDialog(BuildContext context, TasksProvider provider) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = TimeOfDay.now();
    TaskType selectedType = TaskType.meeting;
    String recurrence = "none";
    int reminderHours = 24;

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
                autofocus: true,
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Opis'),
                maxLines: 2,
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
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
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
                items: TaskType.values.map((type) => DropdownMenuItem(value: type, child: Text(type.displayName))).toList(),
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
              DropdownButtonFormField<int>(
                value: reminderHours,
                decoration: const InputDecoration(labelText: 'Przypomnienie'),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Brak')),
                  DropdownMenuItem(value: 1, child: Text('1 godzina przed')),
                  DropdownMenuItem(value: 24, child: Text('1 dzień przed')),
                  DropdownMenuItem(value: 168, child: Text('1 tydzień przed')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => reminderHours = value);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Anuluj')),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty) return;

              final dateTime = DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
                selectedTime.hour,
                selectedTime.minute,
              );

              provider.addTask(
                titleController.text.trim(),
                dateTime,
                selectedType,
                description: descController.text.trim(),
                recurrence: recurrence,
              );

              Navigator.pop(context);

              setState(() {
                _selectedDay = dateTime;
                _focusedDay = dateTime;
              });
            },
            child: const Text('Dodaj'),
          ),
        ],
      ),
    );
  }

  void _confirmArchiveOrDelete(BuildContext context, TasksProvider provider, Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Co chcesz zrobić?'),
        content: Text('„${task.title}”'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Anuluj')),
          TextButton(
            onPressed: () {
              provider.toggleDone(task.id);
              Navigator.pop(context);
            },
            child: const Text('Archiwizuj', style: TextStyle(color: Colors.blue)),
          ),
          TextButton(
            onPressed: () {
              provider.deleteTask(task.id);
              Navigator.pop(context);
            },
            child: const Text('Usuń', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditTaskDialog(BuildContext context, TasksProvider provider, Task task) {
    final titleController = TextEditingController(text: task.title);
    final descController = TextEditingController(text: task.description);
    DateTime selectedDate = task.dateTime;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(task.dateTime);
    TaskType selectedType = TaskType.values.byName(task.type);
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
                maxLines: 2,
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
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
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
                items: TaskType.values.map((type) => DropdownMenuItem(value: type, child: Text(type.displayName))).toList(),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Anuluj')),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty) return;

              final dateTime = DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
                selectedTime.hour,
                selectedTime.minute,
              );

              final updatedTask = Task(
                id: task.id,
                title: titleController.text.trim(),
                description: descController.text.trim(),
                dateTime: dateTime,
                type: selectedType.name,
                isDone: task.isDone,
                recurrence: recurrence,
              );

              updatedTask.save();
              provider.notifyListeners();

              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Zapisz zmiany'),
          ),
        ],
      ),
    );
  }
}