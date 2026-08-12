import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/evaluer_models.dart';
import '../../data/evaluer_repository.dart';
import '../widgets/service_card.dart';
import 'fullscreen_image_viewer.dart';
import 'service_details_screen.dart';
import '../../../rating/presentation/widgets/rating_sheet.dart';
import '../../../comments/presentation/screens/comments_screen.dart';

/// §20 : "Cette service semble déjà exister."
/// NE JAMAIS bannir l'utilisateur ni supprimer son compte ni présumer
/// une fraude. Propose "Voir la service" et "Demander la propriété".
class DuplicateFoundScreen extends StatelessWidget {
  final List<QotaEntity> potentialDuplicates;
  final VoidCallback onCreateAnyway;

  const DuplicateFoundScreen({
    super.key,
    required this.potentialDuplicates,
    required this.onCreateAnyway,
  });

  @override
  Widget build(BuildContext context) {
    final repository = EvaluerRepository();

    return Scaffold(
      appBar: AppBar(title: const Text('Vérification')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Cette service semble déjà exister.',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: potentialDuplicates.length,
              itemBuilder: (context, index) {
                final entity = potentialDuplicates[index];
                return Column(
                  children: [
                    ServiceCard(
                      entity: entity,
                      onOpenDetails: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) =>
                                ServiceDetailsScreen(entityId: entity.id)),
                      ),
                      onOpenRatingSheet: () =>
                          RatingSheet.show(context, entityId: entity.id),
                      onOpenComments: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CommentsScreen(
                              entityId: entity.id, entityKind: 'service'),
                        ),
                      ),
                      onOpenImageFullscreen: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              FullscreenImageViewer(imageUrl: entity.imageUrl),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) => ServiceDetailsScreen(
                                          entityId: entity.id)),
                                );
                              },
                              child: const Text('Voir la service'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primaryOrange),
                              onPressed: () async {
                                await repository.requestOwnership(
                                    entityId: entity.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Demande de propriété envoyée.')),
                                  );
                                  Navigator.of(context).pop();
                                }
                              },
                              child: const Text('Demander la propriété'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextButton(
              onPressed: onCreateAnyway,
              child: const Text(
                  'Aucune de ces services ne correspond — continuer la création'),
            ),
          ),
        ],
      ),
    );
  }
}
