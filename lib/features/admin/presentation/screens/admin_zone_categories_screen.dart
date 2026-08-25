import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/admin_repository.dart';

/// Coche/décoche les catégories actives pour CETTE zone (§029,
/// migration 032) — chaque zone a désormais ses propres catégories,
/// plus une liste globale partagée par toutes les zones.
class AdminZoneCategoriesScreen extends StatefulWidget {
  final String zoneId;
  final String zoneName;

  const AdminZoneCategoriesScreen(
      {super.key, required this.zoneId, required this.zoneName});

  @override
  State<AdminZoneCategoriesScreen> createState() =>
      _AdminZoneCategoriesScreenState();
}

class _AdminZoneCategoriesScreenState extends State<AdminZoneCategoriesScreen> {
  final _repository = AdminRepository();
  List<Map<String, dynamic>> _categories = [];
  Set<String> _linkedIds = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final categories = await _repository.getAllCategories();
      final linkedIds = await _repository.getZoneCategoryIds(widget.zoneId);
      setState(() {
        _categories = categories;
        _linkedIds = linkedIds;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _toggle(String categoryId, bool checked) async {
    setState(() {
      if (checked) {
        _linkedIds.add(categoryId);
      } else {
        _linkedIds.remove(categoryId);
      }
    });
    if (checked) {
      await _repository.addCategoryToZone(
          zoneId: widget.zoneId, categoryId: categoryId);
    } else {
      await _repository.removeCategoryFromZone(
          zoneId: widget.zoneId, categoryId: categoryId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Catégories — ${widget.zoneName}')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Erreur : $_error', textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () {
                            setState(() => _isLoading = true);
                            _load();
                          },
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              : _categories.isEmpty
                  ? const Center(
                      child: Text('Aucune catégorie pour le moment.'))
                  : ListView.separated(
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final id = category['id'] as String;
                        return CheckboxListTile(
                          value: _linkedIds.contains(id),
                          activeColor: AppColors.primaryOrange,
                          title: Text(category['name_fr'] as String),
                          subtitle: Text(category['name_ar'] as String,
                              textDirection: TextDirection.rtl),
                          onChanged: (checked) => _toggle(id, checked ?? false),
                        );
                      },
                    ),
    );
  }
}
