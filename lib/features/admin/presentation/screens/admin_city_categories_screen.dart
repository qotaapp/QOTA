import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/admin_repository.dart';

/// Coche/décoche les catégories actives pour CETTE ville (§029) —
/// chaque ville a désormais ses propres catégories, plus une liste
/// globale partagée par toutes les villes.
class AdminCityCategoriesScreen extends StatefulWidget {
  final String cityId;
  final String cityName;

  const AdminCityCategoriesScreen(
      {super.key, required this.cityId, required this.cityName});

  @override
  State<AdminCityCategoriesScreen> createState() =>
      _AdminCityCategoriesScreenState();
}

class _AdminCityCategoriesScreenState extends State<AdminCityCategoriesScreen> {
  final _repository = AdminRepository();
  List<Map<String, dynamic>> _categories = [];
  Set<String> _linkedIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final categories = await _repository.getAllCategories();
    final linkedIds = await _repository.getCityCategoryIds(widget.cityId);
    setState(() {
      _categories = categories;
      _linkedIds = linkedIds;
      _isLoading = false;
    });
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
      await _repository.addCategoryToCity(
          cityId: widget.cityId, categoryId: categoryId);
    } else {
      await _repository.removeCategoryFromCity(
          cityId: widget.cityId, categoryId: categoryId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Catégories — ${widget.cityName}')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
