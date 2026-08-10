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
  late Future<List<QotaEntity>> _futureServices;

  @override
  void initState() {
    super.initState();
    _futureServices = _repository.getServices(
      categoryId: widget.category.id,
      cityId: widget.cityId,
      zoneId: widget.zoneId,
    );
  }

  void _reloadServices() {
    setState(() {
      _futureServices = _repository.getServices(
        categoryId: widget.category.id,
        cityId: widget.cityId,
        zoneId: widget.zoneId,
      );
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
          Expanded(
            child: FutureBuilder<List<QotaEntity>>(
              future: _futureServices,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final services = snapshot.data ?? [];
                if (services.isEmpty) {
                  return const Center(
                    child: Text('Aucune service pour le moment',
                        style: TextStyle(color: AppColors.textSecondary)),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final entity = services[index];
                    return ServiceCard(
                      entity: entity,
                      onOpenDetails: () {
                        Navigator.of(context)
                            .push(MaterialPageRoute(
                              builder: (_) => ServiceDetailsScreen(entityId: entity.id),
                            ))
                            .then((_) => _reloadServices());
                      },
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
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CommentsScreen(
                              entityId: entity.id,
                              entityKind: 'service',
                            ),
                          ),
                        ).then((_) => _reloadServices());
                      },
                      onOpenImageFullscreen: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => FullscreenImageViewer(imageUrl: entity.imageUrl),
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
