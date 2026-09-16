import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/entity_action_pills.dart';
import '../../../../core/widgets/adaptive_network_image.dart';
import '../../../../core/widgets/call_phone_button.dart';
import '../../data/evaluer_models.dart';
import '../../data/evaluer_repository.dart';
import 'fullscreen_image_viewer.dart';
import '../../../rating/presentation/widgets/rating_sheet.dart';
import '../../../comments/presentation/screens/comments_screen.dart';

/// §26 : fiche d'une Service, affichée en dialog centré par-dessus
/// l'écran courant (Feed, liste Services, Chaînes/Vente en
/// ligne/Autres). Réutilise les mêmes actions que la carte.
class ServiceDetailsScreen extends StatefulWidget {
  final String entityId;

  const ServiceDetailsScreen({super.key, required this.entityId});

  /// Ouvre la fiche en dialog centré, dimensionné à son contenu
  /// (IntrinsicHeight) et plafonné à 640px (scroll au-delà).
  static Future<void> show(
    BuildContext context, {
    required String entityId,
    VoidCallback? onDismiss,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 640),
          child: IntrinsicHeight(
            child: ServiceDetailsScreen(entityId: entityId),
          ),
        ),
      ),
    );
    onDismiss?.call();
  }

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
    return FutureBuilder<QotaEntity?>(
      future: _futureEntity,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final entity = snapshot.data;
        if (entity == null) {
          return const SizedBox(
            height: 140,
            child: Center(child: Text('Service introuvable')),
          );
        }

        return Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              FullscreenImageViewer(imageUrl: entity.imageUrl),
                        ),
                      ),
                      child: AdaptiveNetworkImage(imageUrl: entity.imageUrl),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                          fontSize: 20, fontWeight: FontWeight.w800)),
                  if (entity.locationLabel.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(entity.locationLabel,
                        style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                  if (entity.phoneNumber != null &&
                      entity.phoneNumber!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    CallPhoneButton(phoneNumber: entity.phoneNumber!),
                  ],
                  const SizedBox(height: 14),
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
                  const SizedBox(height: 24),
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
                                    entityId: entity.id, entityKind: 'service'),
                              ))
                              .then((_) => _reload()),
                          icon: const Icon(Icons.chat_bubble_outline_rounded),
                          label: const Text('Commenter'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.35),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        );
      },
    );
  }
}
