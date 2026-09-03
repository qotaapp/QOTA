import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/admin_listing_repository.dart';
import '../../data/evaluer_models.dart';
import '../../../admin/data/admin_repository.dart';
import 'admin_listing_list_screen.dart';

/// Catégories À L'INTÉRIEUR d'une section admin (ex. "Vente en
/// ligne") — gérées EXCLUSIVEMENT par le Super Admin : lui seul voit
/// le bouton "+" et les actions modifier/désactiver/supprimer sur
/// chaque ligne. Tout utilisateur peut consulter la liste et taper
/// une catégorie pour parcourir/publier dedans (AdminListingListScreen).
class AdminListingCategoryListScreen extends StatefulWidget {
  final String typeSlug;
  final String fallbackLabel;

  const AdminListingCategoryListScreen(
      {super.key, required this.typeSlug, required this.fallbackLabel});

  @override
  State<AdminListingCategoryListScreen> createState() =>
      _AdminListingCategoryListScreenState();
}

class _AdminListingCategoryListScreenState
    extends State<AdminListingCategoryListScreen> {
  final _repository = AdminListingRepository();
  final _adminRepository = AdminRepository();

  AdminListingType? _type;
  bool _isSuperAdmin = false;
  bool _notFound = false;
  String? _loadError;
  Future<List<AdminListingCategory>>? _futureCategories;

  @override
  void initState() {
    super.initState();
    _loadType();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final isAdmin = await _adminRepository.isCurrentUserSuperAdmin();
    if (mounted) setState(() => _isSuperAdmin = isAdmin);
  }

  Future<void> _loadType() async {
    try {
      final type = await _repository.getTypeBySlug(widget.typeSlug);
      if (!mounted) {
        return;
      }
      if (type == null) {
        setState(() => _notFound = true);
        return;
      }
      setState(() {
        _type = type;
        _futureCategories =
            _repository.getCategories(type.id, activeOnly: false);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e.toString());
    }
  }

  void _reload() {
    if (_type == null) return;
    setState(() => _futureCategories =
        _repository.getCategories(_type!.id, activeOnly: false));
  }

  Future<void> _openForm({AdminListingCategory? existing}) async {
    if (_type == null) return;
    final nameFrController =
        TextEditingController(text: existing?.nameFr ?? '');
    final nameArController =
        TextEditingController(text: existing?.nameAr ?? '');

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
        typeId: _type!.id,
        nameFr: nameFrController.text.trim(),
        nameAr: nameArController.text.trim(),
      );
    } else {
      await _repository.updateCategory(
        existing.id,
        nameFr: nameFrController.text.trim(),
        nameAr: nameArController.text.trim(),
      );
    }
    _reload();
  }

  Future<void> _confirmDelete(AdminListingCategory category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette catégorie ?'),
        content: Text(
            '"${category.nameFr}" sera supprimée définitivement. Cette action est irréversible.'),
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

    if (confirmed != true) {
      return;
    }

    try {
      await _repository.deleteCategory(category.id);
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Impossible de supprimer : catégorie encore utilisée par des publications.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_type?.nameFr ?? widget.fallbackLabel)),
      body: _notFound
          ? const Center(child: Text('Cette section n\'est plus disponible.'))
          : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Erreur : $_loadError',
                        textAlign: TextAlign.center),
                  ),
                )
              : FutureBuilder<List<AdminListingCategory>>(
                  future: _futureCategories,
                  builder: (context, snapshot) {
                    if (_futureCategories == null ||
                        snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    // Un utilisateur normal ne voit jamais une
                    // catégorie désactivée ; le Super Admin si, pour
                    // pouvoir la réactiver.
                    final categories = (snapshot.data ?? [])
                        .where((c) => c.active || _isSuperAdmin)
                        .toList();
                    if (categories.isEmpty) {
                      return Center(
                        child: Text(
                          _isSuperAdmin
                              ? 'Aucune catégorie. Appuyez sur + pour en créer une.'
                              : 'Rien dans "${_type?.nameFr ?? widget.fallbackLabel}" pour le moment',
                          style:
                              const TextStyle(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        return ListTile(
                          title: Text(
                            category.nameFr,
                            style: TextStyle(
                              color: category.active
                                  ? null
                                  : AppColors.textSecondary,
                            ),
                          ),
                          subtitle: Text(category.nameAr,
                              textDirection: TextDirection.rtl),
                          trailing: _isSuperAdmin
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Switch(
                                      value: category.active,
                                      activeThumbColor: AppColors.primaryOrange,
                                      onChanged: (value) async {
                                        await _repository.toggleCategoryActive(
                                            category.id, value);
                                        _reload();
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined,
                                          color: AppColors.iconDefault),
                                      onPressed: () =>
                                          _openForm(existing: category),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.red),
                                      onPressed: () => _confirmDelete(category),
                                    ),
                                  ],
                                )
                              : const Icon(Icons.chevron_right_rounded,
                                  color: AppColors.iconInactive),
                          onTap: () => Navigator.of(context)
                              .push(
                                MaterialPageRoute(
                                  builder: (_) => AdminListingListScreen(
                                    typeSlug: widget.typeSlug,
                                    fallbackLabel: category.nameFr,
                                    categoryId: category.id,
                                    categoryLabel: category.nameFr,
                                  ),
                                ),
                              )
                              .then((_) => _reload()),
                        );
                      },
                    );
                  },
                ),
      floatingActionButton: _isSuperAdmin
          ? FloatingActionButton(
              backgroundColor: AppColors.primaryOrange,
              onPressed: () => _openForm(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
