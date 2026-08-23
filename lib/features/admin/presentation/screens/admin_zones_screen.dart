import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/admin_repository.dart';
import 'admin_zone_categories_screen.dart';

/// Créer / supprimer les Zones d'une Ville — mêmes règles d'accès que
/// AdminCitiesScreen (Super Admin ou modérateur 'manage_geography').
class AdminZonesScreen extends StatefulWidget {
  final String cityId;
  final String cityName;

  const AdminZonesScreen(
      {super.key, required this.cityId, required this.cityName});

  @override
  State<AdminZonesScreen> createState() => _AdminZonesScreenState();
}

class _AdminZonesScreenState extends State<AdminZonesScreen> {
  final _repository = AdminRepository();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.getZonesForCity(widget.cityId);
  }

  void _reload() {
    setState(() => _future = _repository.getZonesForCity(widget.cityId));
  }

  Future<void> _openForm({Map<String, dynamic>? existing}) async {
    final nameFrController =
        TextEditingController(text: existing?['name_fr'] ?? '');
    final nameArController =
        TextEditingController(text: existing?['name_ar'] ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Nouvelle Zone' : 'Modifier la Zone'),
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
      await _repository.createZone(
          cityId: widget.cityId,
          nameFr: nameFrController.text.trim(),
          nameAr: nameArController.text.trim());
    } else {
      await _repository.updateZone(existing['id'] as String,
          nameFr: nameFrController.text.trim(),
          nameAr: nameArController.text.trim());
    }
    _reload();
  }

  Future<void> _confirmDelete(Map<String, dynamic> zone) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette Zone ?'),
        content:
            Text('"${zone['name_fr']}" sera supprimée définitivement. Cette '
                'action est irréversible.'),
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
      await _repository.deleteZone(zone['id'] as String);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Zones — ${widget.cityName}')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final zones = snapshot.data ?? [];
          if (zones.isEmpty) {
            return const Center(
              child: Text('Aucune Zone pour le moment.'),
            );
          }
          return ListView.separated(
            itemCount: zones.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final zone = zones[index];
              final active = zone['active'] as bool;
              return ListTile(
                title: Text(zone['name_fr'] as String),
                subtitle: Text(zone['name_ar'] as String,
                    textDirection: TextDirection.rtl),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: active,
                      activeThumbColor: AppColors.primaryOrange,
                      onChanged: (value) async {
                        await _repository.toggleZoneActive(
                            zone['id'] as String, value);
                        _reload();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.category_outlined,
                          color: AppColors.iconDefault),
                      tooltip: 'Catégories de cette zone',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AdminZoneCategoriesScreen(
                            zoneId: zone['id'] as String,
                            zoneName: zone['name_fr'] as String,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          color: AppColors.iconDefault),
                      onPressed: () => _openForm(existing: zone),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _confirmDelete(zone),
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
