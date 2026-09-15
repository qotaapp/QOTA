import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/evaluer_repository.dart';
import '../../data/evaluer_models.dart';
import '../widgets/service_card.dart';
import 'add_service_screen.dart';
import 'fullscreen_image_viewer.dart';
import 'service_details_screen.dart';
import '../../../rating/presentation/widgets/rating_sheet.dart';
import '../../../comments/presentation/screens/comments_screen.dart';

/// §18/§25-26 : liste des Services d'une catégorie, sous forme de cartes.
class ServiceListScreen extends StatefulWidget {
  final QotaCategory category;
  final String stateId;
  final String cityId;
  final String? zoneId;
  final String locationLabel;

  const ServiceListScreen({
    super.key,
    required this.category,
    required this.stateId,
    required this.cityId,
    required this.locationLabel,
    this.zoneId,
  });

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  final _repository = EvaluerRepository();
  final _searchController = TextEditingController();
  late Future<List<QotaEntity>> _futureServices;
  List<QotaEntity> _allServices = [];
  List<QotaEntity> _filteredServices = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _futureServices = _repository.getServices(
      categoryId: widget.category.id,
      cityId: widget.cityId,
      zoneId: widget.zoneId,
    );
    _searchController.addListener(_filterServices);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterServices() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredServices = _allServices;
      } else {
        _filteredServices = _allServices.where((service) {
          final name = service.name.toLowerCase();
          final description = (service.description ?? '').toLowerCase();
          return name.contains(query) || description.contains(query);
        }).toList();
      }
    });
  }

  void _reloadServices() {
    setState(() {
      _futureServices = _repository.getServices(
        categoryId: widget.category.id,
        cityId: widget.cityId,
        zoneId: widget.zoneId,
      );
      _searchController.clear();
      _filteredServices = [];
    });
  }

  Future<void> _openAddService() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddServiceScreen(
          category: widget.category,
          stateId: widget.stateId,
          cityId: widget.cityId,
          zoneId: widget.zoneId,
          locationLabel: widget.locationLabel,
        ),
      ),
    );
    if (created == true) {
      _reloadServices();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.nameFr),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(widget.locationLabel,
                  style: const TextStyle(color: AppColors.textSecondary)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Chercher dans ${widget.category.nameFr}...',
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.iconInactive),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: AppColors.iconInactive),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<QotaEntity>>(
              future: _futureServices,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                _allServices = snapshot.data ?? [];
                if (_allServices.isEmpty) {
                  return const Center(
                    child: Text('Aucune service pour le moment',
                        style: TextStyle(color: AppColors.textSecondary)),
                  );
                }

                // Appliquer le filtre initial
                if (_filteredServices.isEmpty && _searchQuery.isEmpty) {
                  _filteredServices = _allServices;
                }

                if (_filteredServices.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Aucun résultat pour "$_searchQuery"',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: _filteredServices.length,
                  itemBuilder: (context, index) {
                    final entity = _filteredServices[index];
                    return ServiceCard(
                      entity: entity,
                      onOpenDetails: () => ServiceDetailsScreen.show(
                        context,
                        entityId: entity.id,
                        onDismiss: _reloadServices,
                      ),
                      onOpenRatingSheet: () {
                        // §29 : Rating Sheet — recharge la carte après publication
                        // pour refléter la nouvelle moyenne/nombre d'évaluations.
                        RatingSheet.show(
                          context,
                          entityId: entity.id,
                          onSubmitted: _reloadServices,
                        );
                      },
                      onOpenComments: () {
                        // §31 : commentaires — kind='service', donc le propriétaire
                        // n'a PAS le droit de suppression arbitraire (§34).
                        Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                builder: (_) => CommentsScreen(
                                  entityId: entity.id,
                                  entityKind: 'service',
                                ),
                              ),
                            )
                            .then((_) => _reloadServices());
                      },
                      onOpenImageFullscreen: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => FullscreenImageViewer(
                                imageUrl: entity.imageUrl),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryOrange,
        onPressed: _openAddService,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
    );
  }
}
