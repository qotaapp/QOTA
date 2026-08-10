import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/auth_repository.dart';
import 'signup_screen.dart';

/// §4 : page de connexion simple.
/// Champs : "E-mail ou Adresse" / "Mot de passe".
/// Bouton "Connexion", puis "Mot de passe oublié ?", "Pas encore de
/// compte", "Connexion avec Facebook/Gmail", "Créer un compte".
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authRepository = AuthRepository();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _authRepository.signIn(
        emailOrAddress: _identifierController.text.trim(),
        password: _passwordController.text,
      );
      // La navigation vers Home se fait automatiquement via
      // authStateChanges dans AuthGate (main.dart).
    } catch (e) {
      setState(() => _errorMessage = 'Identifiants incorrects. Réessayez.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _identifierController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Saisissez votre e-mail pour réinitialiser le mot de passe.');
      return;
    }
    await _authRepository.sendPasswordResetEmail(email);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('E-mail de réinitialisation envoyé.')),
      );
    }
  }

  void _goToSignup() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SignupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Text(
                  'Qota',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryOrange,
                  ),
                ),
                const SizedBox(height: 48),

                // §4 : "E-mail ou Adresse"
                TextField(
                  controller: _identifierController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-mail ou Adresse',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // §4 : "Mot de passe"
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe',
                    border: OutlineInputBorder(),
                  ),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                ],

                const SizedBox(height: 24),

                // §4 : bouton "Connexion"
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Connexion'),
                ),

                const SizedBox(height: 12),

                // §4 : "Mot de passe oublié ?"
                TextButton(
                  onPressed: _handleForgotPassword,
                  child: const Text('Mot de passe oublié ?'),
                ),

                const SizedBox(height: 8),
                const Text('Pas encore de compte', textAlign: TextAlign.center),
                const SizedBox(height: 16),

                // §4-5 : "Connexion avec Facebook/Gmail"
                OutlinedButton.icon(
                  onPressed: () {
                    // Ouvre le choix Facebook / Google (à détailler en widget dédié)
                    _showSocialChoice();
                  },
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Connexion avec Facebook/Gmail'),
                ),
                const SizedBox(height: 12),

                // §4 : "Créer un compte"
                OutlinedButton(
                  onPressed: _goToSignup,
                  child: const Text('Créer un compte'),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSocialChoice() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.facebook),
              title: const Text('Continuer avec Facebook'),
              onTap: () async {
                Navigator.pop(context);
                await _authRepository.signInWithFacebook();
              },
            ),
            ListTile(
              leading: const Icon(Icons.mail_outline),
              title: const Text('Continuer avec Gmail'),
              onTap: () async {
                Navigator.pop(context);
                await _authRepository.signInWithGoogle();
              },
            ),
          ],
        ),
      ),
    );
  }
}
