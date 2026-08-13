import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/auth_repository.dart';

/// §6 : Nom, Prénom, Âge, E-mail, Mot de passe, Rétablir mot de passe.
/// Le bouton "Créer un compte" n'est actif que si tout est valide.
/// Succès -> "Compte créé avec succès" -> redirection directe vers Home.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authRepository = AuthRepository();

  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authRepository.signUp(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      // On vérifie la session RÉELLEMENT, plutôt que de supposer que
      // signUp() a connecté l'utilisateur : si la confirmation par
      // e-mail est activée côté Supabase, aucune session n'existe
      // encore à ce stade, et rediriger vers Home serait trompeur.
      final hasActiveSession = _authRepository.isLoggedIn;

      if (hasActiveSession) {
        // §6 : "Compte créé avec succès" puis redirection directe vers Home.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compte créé avec succès')),
        );
        // AuthGate (main.dart) détecte automatiquement la session active
        // via authStateChanges et affiche RootShell (Home).
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        // Compte créé côté Supabase, mais pas encore de session active
        // -> très probablement la confirmation par e-mail est activée
        // dans Authentication > Providers > Email (Supabase Dashboard).
        setState(() {
          _isLoading = false;
          _errorMessage = 'Compte créé, mais aucune session active. '
              'Si la confirmation par e-mail est activée dans Supabase, '
              'vérifiez votre boîte mail avant de vous connecter.';
        });
      }
    } catch (e) {
      // On affiche le message réel de Supabase (ex: "User already
      // registered", "Password should be at least 6 characters"...)
      // au lieu d'un texte générique qui masquerait la vraie cause.
      setState(() => _errorMessage = 'Erreur : $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'Nom', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'Prénom', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Prénom requis' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Âge', border: OutlineInputBorder()),
                  validator: (v) {
                    final age = int.tryParse(v ?? '');
                    if (age == null || age <= 0 || age > 120) {
                      return 'Âge invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder()),
                  validator: (v) {
                    if (v == null || !v.contains('@')) {
                      return 'E-mail invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Mot de passe', border: OutlineInputBorder()),
                  validator: (v) {
                    if (v == null || v.length < 6) {
                      return 'Minimum 6 caractères';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Rétablir mot de passe', border: OutlineInputBorder()),
                  validator: (v) {
                    if (v != _passwordController.text) {
                      return 'Les mots de passe ne correspondent pas';
                    }
                    return null;
                  },
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                ],

                const SizedBox(height: 28),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isLoading ? null : _handleCreateAccount,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Créer un compte'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
