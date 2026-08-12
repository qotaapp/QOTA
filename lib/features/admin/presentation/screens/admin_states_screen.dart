import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/admin_repository.dart';

/// §14 : "Le Super Admin doit pouvoir ajouter/modifier/désactiver/
/// réactiver un État et gérer sa traduction arabe/française."
class AdminStatesScreen extends StatefulWidget {
  const AdminStatesScreen({super.key});

  @override
  State<AdminStatesScreen> createState() => _AdminStatesScreenState();
}

class _AdminStatesScreenState extends State<AdminStatesScreen> {
  final _repository = AdminRepository();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.getAllStates();
  }

  void _reload() => setState(() => _future = _repository.getAllStates());

  Future<void> _openForm({Map<String, dynamic>? existing}) async {
    final nameFrController =
        TextEditingController(text: existing?['name_fr'] ?? '');
    final nameArController =
        TextEditingController(text: existing?['name_ar'] ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Nouvel État' : 'Modifier l\'État'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameFrController,
                decoration: const InputDecoration(labelText: 'Nom (Français)')),
            const SizedBox(height: 8),
            TextField(
                controller: nameArController,
                decoration: const InputDecoration(labelText: 'الاسم (Arabe)'),
                textDirection: TextDirection.rtl),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Enregistrer')),
        ],
      ),
    );

    if (saved != true) {
      return;
    }

    if (existing == null) {
      await _repository.createState(
          nameFr: nameFrController.text.trim(),
          nameAr: nameArController.text.trim());
    } else {
      await _repository.updateState(existing['id'] as String,
          nameFr: nameFrController.text.trim(),
          nameAr: nameArController.text.trim());
    }
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('États')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final states = snapshot.data ?? [];
          return ListView.separated(
            itemCount: states.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final state = states[index];
              final active = state['active'] as bool;
              return ListTile(
                title: Text(state['name_fr'] as String),
                subtitle: Text(state['name_ar'] as String,
                    textDirection: TextDirection.rtl),
                onTap: () => _openForm(existing: state),
                trailing: Switch(
                  value: active,
                  activeThumbColor: AppColors.primaryOrange,
                  onChanged: (value) async {
                    await _repository.toggleStateActive(
                        state['id'] as String, value);
                    _reload();
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryOrange,
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
