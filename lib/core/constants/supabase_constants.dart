/// Configuration Supabase — lue depuis --dart-define en CI/CD (voir
/// .github/workflows/ci_cd.yml) pour ne jamais committer les clés en
/// dur. En développement local, passer les mêmes flags à `flutter run` :
///
///   flutter run \
///     --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=xxxx
///
/// Les valeurs par défaut ci-dessous sont des placeholders explicites,
/// jamais des identifiants réels.
class SupabaseConstants {
  SupabaseConstants._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://YOUR_PROJECT_REF.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_SUPABASE_ANON_KEY',
  );
}
