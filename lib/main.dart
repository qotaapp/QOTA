import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/root_shell.dart';
import 'core/constants/supabase_constants.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Si Supabase.initialize() échoue (URL/clé invalides, pas de réseau),
  // on ne laisse JAMAIS une page blanche silencieuse : on affiche un
  // écran d'erreur explicite à la place de runApp(QotaApp()).
  try {
    await Supabase.initialize(
      url: SupabaseConstants.url,
      publishableKey: SupabaseConstants.publishableKey,
    );
    runApp(const QotaApp());
  } catch (error, stackTrace) {
    debugPrint('Échec de Supabase.initialize : $error\n$stackTrace');
    runApp(_StartupErrorApp(error: error));
  }
}

/// Affiché uniquement si Supabase.initialize() a échoué — le cas le
/// plus fréquent est SUPABASE_URL/SUPABASE_ANON_KEY encore sur leurs
/// valeurs placeholder (voir lib/core/constants/supabase_constants.dart).
class _StartupErrorApp extends StatelessWidget {
  final Object error;
  const _StartupErrorApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Connexion à Supabase impossible',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Vérifiez SUPABASE_URL et SUPABASE_ANON_KEY passés via '
                  '--dart-define (ou lib/core/constants/supabase_constants.dart '
                  'si vous testez sans --dart-define).',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 12),
                Text('$error',
                    style:
                        const TextStyle(fontSize: 12, color: Colors.black38)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class QotaApp extends StatelessWidget {
  const QotaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Qota',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),

      // §2 : bilingue FR (LTR) / AR (RTL). Flutter gère automatiquement
      // la direction du texte selon la locale active — aucun texte
      // ne doit être codé en dur en dehors des fichiers .arb.
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr'),
        Locale('ar'),
      ],

      home: const AuthGate(),
    );
  }
}

/// Bascule automatiquement entre LoginScreen et RootShell (Home) selon
/// l'état de la session Supabase — pas de logique de navigation manuelle
/// à dupliquer dans chaque écran d'auth.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          return const RootShell();
        }
        return const LoginScreen();
      },
    );
  }
}
