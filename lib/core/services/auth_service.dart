import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends ChangeNotifier {
  final supabase = Supabase.instance.client;

  User? get currentUser => supabase.auth.currentUser;
  Session? get currentSession => supabase.auth.currentSession;

  // Stream do nasłuchiwania zmian logowania
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  Future<String?> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: fullName != null ? {'full_name': fullName} : null,
      );
      return null; // sukces
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
    notifyListeners();
  }

  // Opcjonalnie: odśwież sesję
  Future<void> refreshSession() async {
    await supabase.auth.refreshSession();
    notifyListeners();
  }
}