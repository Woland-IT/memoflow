import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/sync_service.dart';
import '../../notes/providers/notes_provider.dart';
import '../../tasks/providers/tasks_provider.dart';
import '../../shopping/providers/shopping_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    final error = await auth.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    _handleAuthResult(error);
  }

  Future<void> _signUp() async {
    setState(() => _isLoading = true);
    _errorMessage = null;

    final auth = Provider.of<AuthService>(context, listen: false);
    
    final error = await auth.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (error == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konto utworzone! Możesz się teraz zalogować.')),
      );
      setState(() => _isLoading = false);
      // Nie przechodzimy automatycznie – użytkownik musi się zalogować po rejestracji
    } else {
      setState(() {
        _errorMessage = error ?? 'Błąd rejestracji';
        _isLoading = false;
      });
    }
  }

  void _handleAuthResult(String? error) async {
    if (error == null && mounted) {
      final notesP = Provider.of<NotesProvider>(context, listen: false);
      final tasksP = Provider.of<TasksProvider>(context, listen: false);
      final shoppingP = Provider.of<ShoppingProvider>(context, listen: false);
      final syncService = Provider.of<SyncService>(context, listen: false);

      await syncService.syncAll(
        notesProvider: notesP,
        tasksProvider: tasksP,
        shoppingProvider: shoppingP,
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      setState(() {
        _errorMessage = error ?? 'Błąd';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MemoFlow - Logowanie')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Witaj w MemoFlow', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Hasło'), obscureText: true),
            if (_errorMessage != null) 
              Padding(padding: const EdgeInsets.only(top: 16), child: Text(_errorMessage!, style: const TextStyle(color: Colors.red))),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _signIn,
              child: _isLoading ? const CircularProgressIndicator() : const Text('Zaloguj się'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _isLoading ? null : _signUp,
              child: const Text('Zarejestruj nowe konto'),
            ),
          ],
        ),
      ),
    );
  }
}