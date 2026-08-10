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
  await Supabase.initialize(
    url: SupabaseConstants.url,
    anonKey: SupabaseConstants.anonKey,
  );
  runApp(const QotaApp());
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
