import 'package:flutter/material.dart';
import 'core/theme.dart';

// Ekrany
import 'features/auth/screens/login_screen.dart';
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
  bool _isDarkMode = false;

  final List<Widget> _screens = [
    const NotesScreen(),
    const TasksScreen(),
    const ShoppingScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MemoFlow',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,

      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => _buildMainScaffold(context),
      },
      builder: (context, child) => child ?? const SizedBox(),
    );
  }

  Widget _buildMainScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MemoFlow'),
        actions: [
          IconButton(
            icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}