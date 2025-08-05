import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Stream of auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Current user
  User? get currentUser => _supabase.auth.currentUser;

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
