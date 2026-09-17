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
  final _searchController = TextEditingController();
  late Future<List<QotaEntity>> _futureFigures;
  List<QotaEntity> _allFigures = [];
  List<QotaEntity> _filteredFigures = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _futureFigures = _repository.getFigures(widget.figureTypeId);
    _searchController.addListener(_filterFigures);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterFigures() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredFigures = _allFigures;
      } else {
        _filteredFigures = _allFigures.where((figure) {
          final name = figure.name.toLowerCase();
          final description = (figure.description ?? '').toLowerCase();
          return name.contains(query) || description.contains(query);
        }).toList();
      }
    });
  }

  void _reload() {
    setState(() {
      _futureFigures = _repository.getFigures(widget.figureTypeId);
      _searchController.clear();
      _filteredFigures = [];
    });
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Chercher dans ${widget.figureTypeLabel}...',
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
              future: _futureFigures,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                _allFigures = snapshot.data ?? [];
                if (_allFigures.isEmpty) {
                  return const Center(
                    child: Text('Aucune figure publique pour le moment',
                        style: TextStyle(color: AppColors.textSecondary)),
                  );
                }

                // Appliquer le filtre initial
                if (_filteredFigures.isEmpty && _searchQuery.isEmpty) {
                  _filteredFigures = _allFigures;
                }

                if (_filteredFigures.isEmpty) {
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
                  itemCount: _filteredFigures.length,
                  itemBuilder: (context, index) {
                    final entity = _filteredFigures[index];
                    return ServiceCard(
                      entity: entity,
                      onOpenDetails: () => ServiceDetailsScreen.show(
                        context,
                        entityId: entity.id,
                        onDismiss: _reload,
                      ),
                      onOpenRatingSheet: () => RatingSheet.show(context,
                          entityId: entity.id, onSubmitted: _reload),
                      onOpenComments: () => Navigator.of(context)
                          .push(MaterialPageRoute(
                            builder: (_) => CommentsScreen(
                                entityId: entity.id,
                                entityKind: 'public_figure'),
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
          ),
        ],
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
