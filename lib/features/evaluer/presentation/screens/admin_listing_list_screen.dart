import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/admin_listing_repository.dart';
import '../../data/evaluer_models.dart';
import '../widgets/service_card.dart';
import 'service_details_screen.dart';
import 'fullscreen_image_viewer.dart';
import 'add_admin_listing_screen.dart';
import '../../../rating/presentation/widgets/rating_sheet.dart';
import '../../../comments/presentation/screens/comments_screen.dart';
import '../../../admin/data/admin_repository.dart';

/// Liste le contenu d'une section admin (Chaînes et programmes /
/// Vente en ligne / Autres). Le bouton "Ajouter" n'apparaît QUE pour
/// le Super Admin ou un modérateur avec la permission
/// 'moderate_content' — un utilisateur normal consulte sans pouvoir
/// publier ici (contrairement aux Services et Figures Publiques).
class AdminListingListScreen extends StatefulWidget {
  /// Identifiant stable (jamais l'UUID, voir admin_listing_types.slug).
  final String typeSlug;
  final String fallbackLabel;

  const AdminListingListScreen(
      {super.key, required this.typeSlug, required this.fallbackLabel});

  @override
  State<AdminListingListScreen> createState() => _AdminListingListScreenState();
}

class _AdminListingListScreenState extends State<AdminListingListScreen> {
  final _repository = AdminListingRepository();
  final _adminRepository = AdminRepository();
  AdminListingType? _type;
  Future<List<QotaEntity>>? _futureListings;
  bool _canAdd = false;
  bool _notFound = false;

  @override
  void initState() {
    super.initState();
    _loadType();
    _loadAccess();
  }

  Future<void> _loadType() async {
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
      _futureListings = _repository.getListings(type.id);
    });
  }

  Future<void> _loadAccess() async {
    final isSuperAdmin = await _adminRepository.isCurrentUserSuperAdmin();
    final canAdd = isSuperAdmin ||
        (await _adminRepository.getMyModeratorPermissions())
            .contains('moderate_content');
    if (mounted) setState(() => _canAdd = canAdd);
  }

  void _reload() {
    if (_type == null) return;
    setState(() => _futureListings = _repository.getListings(_type!.id));
  }

  Future<void> _openAdd() async {
    if (_type == null) return;
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            AddAdminListingScreen(typeId: _type!.id, typeLabel: _type!.nameFr),
      ),
    );
    if (created == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_type?.nameFr ?? widget.fallbackLabel)),
      body: _notFound
          ? const Center(child: Text('Cette section n\'est plus disponible.'))
          : FutureBuilder<List<QotaEntity>>(
              future: _futureListings,
              builder: (context, snapshot) {
                if (_futureListings == null ||
                    snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final listings = snapshot.data ?? [];
                if (listings.isEmpty) {
                  return Center(
                    child: Text(
                        'Rien dans "${_type?.nameFr ?? widget.fallbackLabel}" pour le moment',
                        style: const TextStyle(color: AppColors.textSecondary)),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: listings.length,
                  itemBuilder: (context, index) {
                    final entity = listings[index];
                    return ServiceCard(
                      entity: entity,
                      onOpenDetails: () => Navigator.of(context)
                          .push(MaterialPageRoute(
                              builder: (_) =>
                                  ServiceDetailsScreen(entityId: entity.id)))
                          .then((_) => _reload()),
                      onOpenRatingSheet: () => RatingSheet.show(context,
                          entityId: entity.id, onSubmitted: _reload),
                      onOpenComments: () => Navigator.of(context)
                          .push(MaterialPageRoute(
                            builder: (_) => CommentsScreen(
                                entityId: entity.id,
                                entityKind: 'admin_listing'),
                          ))
                          .then((_) => _reload()),
                      onOpenImageFullscreen: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => FullscreenImageViewer(
                                imageUrl: entity.imageUrl)),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: _canAdd && _type != null
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primaryOrange,
              onPressed: _openAdd,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter'),
            )
          : null,
    );
  }
}
