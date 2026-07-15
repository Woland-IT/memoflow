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

  // ==================== ZAKŁADKI ====================

    // ==================== NADCHODZĄCE ====================
  int _upcomingFilterDays = 30; // domyślnie 30 dni

  Widget _buildUpcomingTab(TasksProvider provider) {
    final now = DateTime.now();
    final cutoffDate = now.add(Duration(days: _upcomingFilterDays));

    final filteredTasks = provider.upcomingTasks.where((task) {
      final date = task.nextOccurrence ?? task.dateTime;
      return date.isBefore(cutoffDate);
    }).toList();

    return Column(
      children: [
        // Filtr zakresu
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [7, 14, 30, 90, 180, 365].map((days) {
                final isSelected = _upcomingFilterDays == days;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(days == 365 ? 'Cały rok' : '$days dni'),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _upcomingFilterDays = days);
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: Colors.blue[100],
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Lista wydarzeń
        Expanded(
          child: filteredTasks.isEmpty
              ? const Center(child: Text('Brak nadchodzących wydarzeń w wybranym okresie'))
              : ListView.builder(
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    final task = filteredTasks[index];
                    return _buildTaskCard(task, provider);
                  },
                ),
        ),
      ],
    );
  }

   // ==================== ROCZNICE Z FILTREM ====================
    // ==================== ROCZNICE ====================
  int _anniversaryFilterDays = 365; // domyślnie 1 rok

  Widget _buildAnniversariesTab(TasksProvider provider) {
    final now = DateTime.now();
    final cutoffDate = now.add(Duration(days: _anniversaryFilterDays));

    final anniversaries = provider.tasks.where((t) => 
      t.type == 'birthday' || t.type == 'nameDay' || t.type == 'deathAnniversary'
    ).toList();

    final filtered = anniversaries.where((task) {
      final nextDate = provider.getNextOccurrence(task);
      return nextDate.isBefore(cutoffDate);
    }).toList();

    return Column(
      children: [
        // Filtr
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                30, 90, 180, 365, 730
              ].map((days) {
                final label = days == 30 ? '30 dni' :
                             days == 90 ? '90 dni' :
                             days == 180 ? '180 dni' :
                             days == 365 ? '1 rok' : '2 lata';
                final isSelected = _anniversaryFilterDays == days;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _anniversaryFilterDays = days);
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: Colors.pink[100],
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        Expanded(
          child: filtered.isEmpty
              ? Center(child: Text('Brak rocznic w wybranym okresie'))
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final task = filtered[index];
                    return _buildTaskCard(task, provider, showNextDate: true);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildArchivedTab(TasksProvider provider) {
    final archived = provider.tasks.where((t) => t.isDone).toList();

    if (archived.isEmpty) {
      return const Center(child: Text('Brak zarchiwizowanych wydarzeń'));
    }

    return ListView.builder(
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
                    child: Text('${events.length}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                );
              }
              return null;
            },
          ),
          calendarStyle: const CalendarStyle(
            markersAlignment: Alignment.bottomRight,
            todayDecoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
            selectedDecoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
          ),
          headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
        ),
        const Divider(),
        Expanded(child: _buildDayEvents(provider)),
      ],
    );
  }

  Widget _buildDayEvents(TasksProvider provider) {
    final dayTasks = provider.getTasksForDay(_selectedDate);
    if (dayTasks.isEmpty) {
      return const Center(child: Text('Brak wydarzeń w tym dniu'));
    }
    return ListView.builder(
      itemCount: dayTasks.length,
      itemBuilder: (context, index) => _buildTaskCard(dayTasks[index], provider),
    );
  }

  // ==================== KARTA ZADANIA ====================
    Widget _buildTaskCard(Task task, TasksProvider provider, {bool isArchived = false, bool showNextDate = false}) {
    final displayDate = task.nextOccurrence ?? task.dateTime;
    final isOverdue = displayDate.isBefore(DateTime.now()) && !task.isDone;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _getTypeColor(task.type).withOpacity(0.2),
          child: Icon(_getIconForType(task.type), color: _getTypeColor(task.type)),
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
              DateFormat('dd.MM.yyyy • HH:mm').format(displayDate),
              style: TextStyle(color: isOverdue ? Colors.red : Colors.grey[600], fontSize: 13),
            ),
            if (task.recurrence != "none")
              Text('Powtarzanie: ${task.recurrence}', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
            if (task.description != null && task.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(task.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
              onPressed: () => _showEditTaskDialog(context, provider, task),
            ),
            IconButton(
              icon: Icon(
                task.isDone ? Icons.unarchive : Icons.archive_outlined,
                size: 20,
                color: task.isDone ? Colors.green : Colors.orange,
              ),
              onPressed: () => provider.toggleDone(task.id),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () => _confirmArchiveOrDelete(context, provider, task),
            ),
          ],
        ),
      ),
    );
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

              final updatedTask = task.copyWith(
                title: titleController.text.trim(),
                description: descController.text.isEmpty ? null : descController.text,
                dateTime: dateTime,
                type: selectedType.name,
                recurrence: recurrence,
              );

              provider.updateTask(updatedTask);

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

}