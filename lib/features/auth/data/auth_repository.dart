import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_constants.dart';

/// Centralise §4-6 : connexion, création de compte, réinitialisation
/// de mot de passe, connexion sociale (Gmail).
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

  /// Définit (ou remplace) le mot de passe du compte actuellement
  /// connecté — utilisé par CompleteProfileScreen pour qu'un compte
  /// créé via Google puisse AUSSI se connecter plus tard par e-mail +
  /// mot de passe, sans créer de second compte.
  Future<void> setPassword(String password) async {
    await _client.auth.updateUser(UserAttributes(password: password));
  }

  /// §5 : connexion sociale.
  /// - Sur mobile (Android/iOS) : ouvre le navigateur système, puis
  ///   revient dans l'app via `oauthRedirectUrl` (deep link
  ///   io.supabase.qota://login-callback/) — AuthGate détecte alors
  ///   automatiquement la nouvelle session (§main.dart).
  /// - Sur Web : un lien mobile (schéma personnalisé) n'a AUCUN sens
  ///   pour un navigateur, qui resterait bloqué indéfiniment. On
  ///   redirige donc vers l'URL web ACTUELLE (Uri.base) — celle-ci
  ///   s'adapte automatiquement, que l'app soit servie sur GitHub
  ///   Pages, Render, ou en local pendant le développement. Chaque
  ///   URL empruntée doit être ajoutée dans Supabase Dashboard >
  ///   Authentication > URL Configuration > Redirect URLs (un
  ///   caractère générique est accepté, ex: https://qotaapp.github.io/**).
  /// Si l'e-mail Google correspond à un compte existant, Supabase lie
  /// automatiquement les deux (à activer dans Authentication >
  /// Settings > "Link accounts by email" si ce n'est pas déjà le cas).
  /// Premier login Google -> compte créé automatiquement
  /// (§handle_new_auth_user, complété en 020 pour en extraire le nom).
  Future<bool> signInWithGoogle() {
    return _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo:
          kIsWeb ? Uri.base.toString() : SupabaseConstants.oauthRedirectUrl,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
