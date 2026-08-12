import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/admin_repository.dart';

/// §16 : créer/modifier/traduire/réordonner/activer-désactiver une catégorie.
class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  final _repository = AdminRepository();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.getAllCategories();
  }

  void _reload() => setState(() => _future = _repository.getAllCategories());

  Future<void> _openForm({Map<String, dynamic>? existing}) async {
    final nameFrController =
        TextEditingController(text: existing?['name_fr'] ?? '');
    final nameArController =
        TextEditingController(text: existing?['name_ar'] ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            existing == null ? 'Nouvelle catégorie' : 'Modifier la catégorie'),
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
      await _repository.createCategory(
          nameFr: nameFrController.text.trim(),
          nameAr: nameArController.text.trim());
    } else {
      await _repository.updateCategory(existing['id'] as String,
          nameFr: nameFrController.text.trim(),
          nameAr: nameArController.text.trim());
    }
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catégories')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final categories = snapshot.data ?? [];
          return ListView.separated(
            itemCount: categories.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final category = categories[index];
              final active = category['active'] as bool;
              return ListTile(
                title: Text(category['name_fr'] as String),
                subtitle: Text(category['name_ar'] as String,
                    textDirection: TextDirection.rtl),
                onTap: () => _openForm(existing: category),
                trailing: Switch(
                  value: active,
                  activeThumbColor: AppColors.primaryOrange,
                  onChanged: (value) async {
                    await _repository.toggleCategoryActive(
                        category['id'] as String, value);
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
