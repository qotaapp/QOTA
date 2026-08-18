import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/admin_repository.dart';

/// Créer des Modérateurs avec un rôle BIEN DÉTERMINÉ : chaque
/// modérateur ne reçoit que les permissions explicitement cochées
/// (jamais un accès total par défaut). Réservé au Super Admin —
/// un modérateur ne peut ni créer ni voir d'autres modérateurs
/// (RLS : `moderators_view` ne renvoie rien en dehors du Super Admin).
class AdminModeratorsScreen extends StatefulWidget {
  const AdminModeratorsScreen({super.key});

  @override
  State<AdminModeratorsScreen> createState() => _AdminModeratorsScreenState();
}

const _kPermissionLabels = {
  'manage_geography': 'Gérer les Villes & Zones',
  'moderate_content': 'Modérer les publications (Services, Figures)',
};

class _AdminModeratorsScreenState extends State<AdminModeratorsScreen> {
  final _repository = AdminRepository();
  late Future<List<AdminModerator>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.getModerators();
  }

  void _reload() => setState(() => _future = _repository.getModerators());

  Future<void> _confirmRevoke(AdminModerator moderator) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer ce modérateur ?'),
        content: Text('${moderator.fullName} perdra immédiatement toutes ses '
            'permissions de modération.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Retirer')),
        ],
      ),
    );
    if (confirmed == true) {
      await _repository.revokeModerator(moderator.id);
      _reload();
    }
  }

  Future<void> _openEditPermissions(AdminModerator moderator) async {
    final saved = await _openPermissionsDialog(
      title: moderator.fullName,
      initialPermissions: moderator.permissions.toSet(),
    );
    if (saved != null) {
      await _repository.setModerator(userId: moderator.id, permissions: saved);
      _reload();
    }
  }

  Future<void> _openAddModerator() async {
    final emailController = TextEditingController();
    AdminUserSearchResult? found;
    String? error;
    var searching = false;

    final result = await showDialog<AdminUserSearchResult>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Désigner un modérateur'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'E-mail du compte existant',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              if (searching) const CircularProgressIndicator(),
              if (!searching && found != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text(found!.fullName),
                ),
              if (!searching && error != null)
                Text(error!, style: const TextStyle(color: Colors.red)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: searching
                  ? null
                  : () async {
                      final email = emailController.text.trim();
                      if (email.isEmpty) return;
                      setDialogState(() {
                        searching = true;
                        error = null;
                      });
                      try {
                        final user = await _repository.findUserByEmail(email);
                        setDialogState(() {
                          searching = false;
                          found = user;
                          error = user == null
                              ? 'Aucun compte avec cet e-mail.'
                              : null;
                        });
                        if (user != null && context.mounted) {
                          Navigator.pop(context, user);
                        }
                      } catch (e) {
                        setDialogState(() {
                          searching = false;
                          error = 'Erreur : $e';
                        });
                      }
                    },
              child: const Text('Rechercher'),
            ),
          ],
        ),
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    final permissions = await _openPermissionsDialog(
      title: result.fullName,
      initialPermissions: const {},
    );
    if (permissions == null) {
      return;
    }
    await _repository.setModerator(userId: result.id, permissions: permissions);
    _reload();
  }

  /// Coche/décoche les permissions -> "rôle bien déterminé" : on ne
  /// valide QUE ce qui est explicitement sélectionné, jamais un
  /// ensemble par défaut.
  Future<Set<String>?> _openPermissionsDialog(
      {required String title, required Set<String> initialPermissions}) {
    final selected = {...initialPermissions};
    return showDialog<Set<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Permissions — $title'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _kPermissionLabels.entries.map((entry) {
              return CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: selected.contains(entry.key),
                title: Text(entry.value),
                activeColor: AppColors.primaryOrange,
                onChanged: (checked) => setDialogState(() {
                  if (checked == true) {
                    selected.add(entry.key);
                  } else {
                    selected.remove(entry.key);
                  }
                }),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange),
              onPressed: () => Navigator.pop(context, selected),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modérateurs')),
      body: FutureBuilder<List<AdminModerator>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final moderators = snapshot.data ?? [];
          if (moderators.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Aucun modérateur pour le moment. Utilisez le bouton "+" '
                  'pour en désigner un via son e-mail.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            );
          }
          return ListView.separated(
            itemCount: moderators.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final moderator = moderators[index];
              final labels = moderator.permissions
                  .map((p) => _kPermissionLabels[p] ?? p)
                  .join(', ');
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.surfaceChip,
                  backgroundImage: moderator.avatarUrl != null
                      ? NetworkImage(moderator.avatarUrl!)
                      : null,
                  child: moderator.avatarUrl == null
                      ? const Icon(Icons.person, color: AppColors.iconInactive)
                      : null,
                ),
                title: Text(moderator.fullName),
                subtitle: Text(
                  labels.isEmpty ? 'Aucune permission accordée' : labels,
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () => _openEditPermissions(moderator),
                trailing: IconButton(
                  icon: const Icon(Icons.person_remove_outlined,
                      color: Colors.red),
                  onPressed: () => _confirmRevoke(moderator),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryOrange,
        onPressed: _openAddModerator,
        child: const Icon(Icons.person_add_alt_1_outlined),
      ),
    );
  }
}
