import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/figures_repository.dart';
import '../../../evaluer/data/evaluer_models.dart';
import '../../../evaluer/presentation/widgets/service_card.dart';
import '../../../evaluer/presentation/screens/service_details_screen.dart';
import '../../../evaluer/presentation/screens/fullscreen_image_viewer.dart';
import '../../../rating/presentation/widgets/rating_sheet.dart';
import '../../../comments/presentation/screens/comments_screen.dart';
import 'add_figure_screen.dart';

/// §35-36 : liste des Figures Publiques d'un type. Réutilise ServiceCard
/// car les mêmes règles de confidentialité s'appliquent (§18/§37 :
/// aucune identité d'auteur ou d'évaluateur affichée publiquement).
class FigureListScreen extends StatefulWidget {
  final String figureTypeId;
  final String figureTypeLabel;

  const FigureListScreen(
      {super.key, required this.figureTypeId, required this.figureTypeLabel});

  @override
  State<FigureListScreen> createState() => _FigureListScreenState();
}

class _FigureListScreenState extends State<FigureListScreen> {
  final _repository = FiguresRepository();
  late Future<List<QotaEntity>> _futureFigures;

  @override
  void initState() {
    super.initState();
    _futureFigures = _repository.getFigures(widget.figureTypeId);
  }

  void _reload() {
    setState(
        () => _futureFigures = _repository.getFigures(widget.figureTypeId));
  }

  Future<void> _openAddFigure() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddFigureScreen(
            figureTypeId: widget.figureTypeId,
            figureTypeLabel: widget.figureTypeLabel),
      ),
    );
    if (created == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.figureTypeLabel)),
      body: FutureBuilder<List<QotaEntity>>(
        future: _futureFigures,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final figures = snapshot.data ?? [];
          if (figures.isEmpty) {
            return const Center(
              child: Text('Aucune figure publique pour le moment',
                  style: TextStyle(color: AppColors.textSecondary)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: figures.length,
            itemBuilder: (context, index) {
              final entity = figures[index];
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
                          entityId: entity.id, entityKind: 'public_figure'),
                    ))
                    .then((_) => _reload()),
                onOpenImageFullscreen: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) =>
                          FullscreenImageViewer(imageUrl: entity.imageUrl)),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryOrange,
        onPressed: _openAddFigure,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
    );
  }
}
