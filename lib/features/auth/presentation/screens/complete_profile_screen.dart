import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routing/root_shell.dart';
import '../../../profile/data/profile_repository.dart';
import '../../data/auth_repository.dart';

/// Affiché par AuthGate (main.dart) juste après une première connexion
/// Google : celle-ci fournit le nom et la photo, mais jamais l'âge ni
/// de mot de passe. Mêmes champs que l'inscription classique (§6) —
/// Nom, Prénom, Âge, E-mail, Mot de passe, Confirmer le mot de passe —
/// pour que le compte soit ensuite utilisable de façon identique,
/// y compris une connexion par e-mail/mot de passe si l'utilisateur
/// le souhaite plus tard.
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authRepository = AuthRepository();
  final _profileRepository = ProfileRepository();

  final _lastNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoadingProfile = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  /// Pré-remplit Nom/Prénom avec ce que Google a déjà fourni (via
  /// handle_new_auth_user, §020) — l'utilisateur n'a qu'à les
  /// confirmer ou les corriger, pas les ressaisir de zéro.
  Future<void> _loadExistingProfile() async {
    try {
      final profile = await _profileRepository.getMyProfile();
      _lastNameController.text = profile.lastName;
      _firstNameController.text = profile.firstName;
    } catch (_) {
      // Champs vides si le pré-remplissage échoue — l'utilisateur les
      // saisit simplement lui-même, ce n'est pas bloquant.
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _ageController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await _profileRepository.updateBasicInfo(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
      );
      await _authRepository.setPassword(_passwordController.text);

      if (!mounted) {
        return;
      }
      // Le profil est maintenant complet -> on va directement à Home,
      // sans attendre un nouvel événement d'authentification (une mise
      // à jour de profil n'en déclenche pas).
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RootShell()),
      );
    } catch (e) {
      setState(() => _errorMessage = 'Erreur : $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complétez votre profil'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: _isLoadingProfile
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Connecté avec Google — plus que quelques infos '
                        'pour finaliser votre compte.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Nom',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Nom requis'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'Prénom',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Prénom requis'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Âge',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final age = int.tryParse(v ?? '');
                          if (age == null || age <= 0 || age > 120) {
                            return 'Âge invalide';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Non modifiable : c'est l'e-mail du compte Google
                      // déjà authentifié — un changement ici nécessiterait
                      // une vérification séparée, hors du périmètre de
                      // cet écran.
                      TextFormField(
                        initialValue: email,
                        enabled: false,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Mot de passe',
                          border: OutlineInputBorder(),
                          helperText:
                              'Vous pourrez aussi vous connecter avec cet '
                              'e-mail et ce mot de passe, en plus de Google.',
                          helperMaxLines: 2,
                        ),
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
                        decoration: const InputDecoration(
                          labelText: 'Confirmer le mot de passe',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v != _passwordController.text) {
                            return 'Les mots de passe ne correspondent pas';
                          }
                          return null;
                        },
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                      const SizedBox(height: 28),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Continuer'),
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
