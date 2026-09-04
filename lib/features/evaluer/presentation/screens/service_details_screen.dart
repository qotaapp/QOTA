import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/entity_action_pills.dart';
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
                      // Visible UNIQUEMENT par le créateur — une Service
                      // pending_review d'un autre utilisateur n'est
                      // jamais renvoyée ici (entity_cards_view). Prévient
                      // que la publication n'est pas encore visible du
                      // public, même si lui peut déjà l'évaluer/commenter.
                      if (entity.isPendingReview) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.4)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.hourglass_top_rounded,
                                  size: 16, color: Colors.orange),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'En attente d\'approbation — visible '
                                  'uniquement par vous pour le moment. '
                                  'Vous pouvez déjà l\'évaluer et la '
                                  'commenter.',
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.textSecondary),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
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

                      // §25 : moyenne / nb évaluations / nb commentaires / nb vues — pas de ❤️.
                      EntityActionPills(
                        averageScore: entity.averageScore,
                        ratingsCount: entity.ratingsCount,
                        commentsCount: entity.commentsCount,
                        viewsCount: entity.viewsCount,
                        onTapRate: () => RatingSheet.show(context,
                            entityId: entity.id, onSubmitted: _reload),
                        onTapComment: () => Navigator.of(context)
                            .push(MaterialPageRoute(
                              builder: (_) => CommentsScreen(
                                  entityId: entity.id, entityKind: 'service'),
                            ))
                            .then((_) => _reload()),
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
