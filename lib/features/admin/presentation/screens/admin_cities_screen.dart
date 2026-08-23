import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/admin_repository.dart';
import 'admin_zones_screen.dart';
import 'admin_city_categories_screen.dart';

/// Créer / supprimer les Villes d'un État — accessible au Super Admin
/// ainsi qu'à tout modérateur détenant la permission 'manage_geography'
/// (contrôlé côté base par la RLS, pas seulement ici).
class AdminCitiesScreen extends StatefulWidget {
  final String stateId;
  final String stateName;

  const AdminCitiesScreen(
      {super.key, required this.stateId, required this.stateName});

  @override
  State<AdminCitiesScreen> createState() => _AdminCitiesScreenState();
}

class _AdminCitiesScreenState extends State<AdminCitiesScreen> {
  final _repository = AdminRepository();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.getCitiesForState(widget.stateId);
  }

  void _reload() {
    setState(() => _future = _repository.getCitiesForState(widget.stateId));
  }

  Future<void> _openForm({Map<String, dynamic>? existing}) async {
    final nameFrController =
        TextEditingController(text: existing?['name_fr'] ?? '');
    final nameArController =
        TextEditingController(text: existing?['name_ar'] ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Nouvelle Ville' : 'Modifier la Ville'),
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
      await _repository.createCity(
          stateId: widget.stateId,
          nameFr: nameFrController.text.trim(),
          nameAr: nameArController.text.trim());
    } else {
      await _repository.updateCity(existing['id'] as String,
          nameFr: nameFrController.text.trim(),
          nameAr: nameArController.text.trim());
    }
    _reload();
  }

  Future<void> _confirmDelete(Map<String, dynamic> city) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette Ville ?'),
        content: Text(
            '"${city['name_fr']}" sera supprimée définitivement, ainsi que '
            'toutes ses Zones. Cette action est irréversible.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer')),
        ],
      ),
    );

    if (confirmed == true) {
      await _repository.deleteCity(city['id'] as String);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Villes — ${widget.stateName}')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final cities = snapshot.data ?? [];
          if (cities.isEmpty) {
            return const Center(
              child: Text('Aucune Ville pour le moment.'),
            );
          }
          return ListView.separated(
            itemCount: cities.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final city = cities[index];
              final active = city['active'] as bool;
              return ListTile(
                title: Text(city['name_fr'] as String),
                subtitle: Text(city['name_ar'] as String,
                    textDirection: TextDirection.rtl),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AdminZonesScreen(
                      cityId: city['id'] as String,
                      cityName: city['name_fr'] as String,
                    ),
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: active,
                      activeThumbColor: AppColors.primaryOrange,
                      onChanged: (value) async {
                        await _repository.toggleCityActive(
                            city['id'] as String, value);
                        _reload();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.category_outlined,
                          color: AppColors.iconDefault),
                      tooltip: 'Catégories de cette ville',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AdminCityCategoriesScreen(
                            cityId: city['id'] as String,
                            cityName: city['name_fr'] as String,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          color: AppColors.iconDefault),
                      onPressed: () => _openForm(existing: city),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _confirmDelete(city),
                    ),
                  ],
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
