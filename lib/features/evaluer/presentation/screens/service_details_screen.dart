import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/evaluer_models.dart';
import '../../data/evaluer_repository.dart';
import 'fullscreen_image_viewer.dart';
import '../../../rating/presentation/widgets/rating_sheet.dart';
import '../../../comments/presentation/screens/comments_screen.dart';

/// §26 : ouverte en cliquant sur la Service (en dehors des zones
/// dédiées ⭐/💬/image). Réutilise les mêmes actions que la carte.
class ServiceDetailsScreen extends StatefulWidget {
  final String entityId;

  const ServiceDetailsScreen({super.key, required this.entityId});

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  final _repository = EvaluerRepository();
  late Future<QotaEntity?> _futureEntity;

  @override
  void initState() {
    super.initState();
    _futureEntity = _repository.getEntityById(widget.entityId);
  }

  void _reload() {
    setState(() => _futureEntity = _repository.getEntityById(widget.entityId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<QotaEntity?>(
        future: _futureEntity,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final entity = snapshot.data;
          if (entity == null) {
            return const Center(child: Text('Service introuvable'));
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 240,
                backgroundColor: AppColors.background,
                flexibleSpace: FlexibleSpaceBar(
                  background: GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            FullscreenImageViewer(imageUrl: entity.imageUrl),
                      ),
                    ),
                    child: CachedNetworkImage(
                        imageUrl: entity.imageUrl, fit: BoxFit.cover),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entity.name,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w800)),
                      if (entity.locationLabel.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(entity.locationLabel,
                            style: const TextStyle(
                                color: AppColors.textSecondary)),
                      ],
                      const SizedBox(height: 14),

                      // §25 : moyenne / nb évaluations / nb commentaires — pas de ❤️.
                      Row(
                        children: [
                          InkWell(
                            onTap: () => RatingSheet.show(context,
                                entityId: entity.id, onSubmitted: _reload),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: AppColors.starFilled, size: 22),
                                const SizedBox(width: 4),
                                Text(entity.averageScore.toStringAsFixed(1),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16)),
                                const SizedBox(width: 6),
                                Text('(${entity.ratingsCount})',
                                    style: const TextStyle(
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          InkWell(
                            onTap: () => Navigator.of(context)
                                .push(MaterialPageRoute(
                                  builder: (_) => CommentsScreen(
                                      entityId: entity.id,
                                      entityKind: 'service'),
                                ))
                                .then((_) => _reload()),
                            child: Row(
                              children: [
                                const Icon(Icons.chat_bubble_outline_rounded,
                                    size: 18),
                                const SizedBox(width: 4),
                                Text('${entity.commentsCount} commentaires'),
                              ],
                            ),
                          ),
                        ],
                      ),

                      if (entity.description != null &&
                          entity.description!.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Text('Description',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(entity.description!),
                      ],

                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primaryOrange),
                              onPressed: () => RatingSheet.show(context,
                                  entityId: entity.id, onSubmitted: _reload),
                              icon: const Icon(Icons.star_rounded),
                              label: const Text('Évaluer'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.of(context)
                                  .push(MaterialPageRoute(
                                    builder: (_) => CommentsScreen(
                                        entityId: entity.id,
                                        entityKind: 'service'),
                                  ))
                                  .then((_) => _reload()),
                              icon:
                                  const Icon(Icons.chat_bubble_outline_rounded),
                              label: const Text('Commenter'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
