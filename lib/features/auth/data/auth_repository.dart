import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralise §4-6 : connexion, création de compte, réinitialisation
/// de mot de passe, connexion sociale (Facebook/Gmail).
class AuthRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  bool get isLoggedIn => _client.auth.currentSession != null;

  /// §4 : champ "E-mail ou Adresse" — Supabase Auth attend un e-mail.
  /// Si un identifiant non-e-mail est saisi, résoudre côté backend
  /// (ex: table de correspondance username -> email) avant appel.
  Future<void> signIn(
      {required String emailOrAddress, required String password}) async {
    await _client.auth.signInWithPassword(
      email: emailOrAddress,
      password: password,
    );
  }

  /// §6 : création de compte. first_name/last_name/age sont transmis
  /// en metadata et récupérés par le trigger SQL `handle_new_auth_user`
  /// qui crée automatiquement profile + wallet + rôle.
  Future<void> signUp({
    required String firstName,
    required String lastName,
    required int age,
    required String email,
    required String password,
  }) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'first_name': firstName,
        'last_name': lastName,
        'age': age,
      },
    );
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  /// §5 : connexion sociale. Supabase gère la liaison de comptes si
  /// l'e-mail du provider correspond à un compte existant (à activer
  /// dans Authentication > Settings > "Link accounts by email").
  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(OAuthProvider.google);
  }

  Future<void> signInWithFacebook() async {
    await _client.auth.signInWithOAuth(OAuthProvider.facebook);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
