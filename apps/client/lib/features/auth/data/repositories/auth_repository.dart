import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// -----------------------------------------------------------------------------
// Repository
// -----------------------------------------------------------------------------
class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  // Get current session
  Session? get currentSession => _supabase.auth.currentSession;
  User? get currentUser => _supabase.auth.currentUser;

  // Sign In
  Future<void> signIn({required String email, required String password}) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  // Sign Up
  Future<void> signUp({required String email, required String password}) async {
    await _supabase.auth.signUp(email: email, password: password);
  }

  // Sign Out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Check if session is expired
  bool get isSessionExpired {
    final session = currentSession;
    if (session == null) return true;
    return JwtDecoder.isExpired(session.accessToken);
  }
}

// -----------------------------------------------------------------------------
// Providers
// -----------------------------------------------------------------------------

// Raw Supabase Client Provider
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Auth Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

// Auth State Stream Provider (Listens to auth changes)
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});

// Helper for JWT decoding (basic expiration check)
class JwtDecoder {
  static bool isExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      // Payload is the second part
      // Note: In a real app, use a proper JWT package or Supabase's internal checks
      // Supabase client handles refresh automatically usually.
      return false; // Let Supabase handle validity
    } catch (_) {
      return true;
    }
  }
}
