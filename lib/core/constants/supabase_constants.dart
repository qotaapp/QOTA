/// Configuration Supabase — lue depuis --dart-define en CI/CD (voir
/// .github/workflows/ci_cd.yml et deploy_pages.yml) pour ne jamais
/// committer les clés en dur. En développement local, passer les
/// mêmes flags à `flutter run` :
///
///   flutter run \
///     --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///     --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxxx
///
/// Les valeurs par défaut ci-dessous sont des placeholders explicites,
/// jamais des identifiants réels.
class SupabaseConstants {
  SupabaseConstants._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://YOUR_PROJECT_REF.supabase.co',
  );

  /// Nommée "Publishable key" dans le Dashboard Supabase actuel
  /// (nouveau format sb_publishable_..., remplace l'ancien anon key
  /// au format JWT eyJ...). Le nom de la variable d'environnement
  /// SUPABASE_PUBLISHABLE_KEY est identique partout dans le projet
  /// (GitHub Secrets, Render, CI/CD) pour éviter toute confusion.
  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'YOUR_SUPABASE_PUBLISHABLE_KEY',
  );
}
