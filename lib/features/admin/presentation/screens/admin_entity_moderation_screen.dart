import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/admin_repository.dart';

/// Approuver / rejeter / supprimer les publications ajoutées par les
/// utilisateurs — Services et Figures publiques UNIQUEMENT. Un User
/// Item (contenu du profil personnel) n'apparaît jamais ici : c'est
/// une exclusion appliquée côté requêtes (AdminRepository) ET côté
/// base (RLS), pas seulement une omission d'affichage.
class AdminEntityModerationScreen extends StatefulWidget {
  const AdminEntityModerationScreen({super.key});

  @override
  State<AdminEntityModerationScreen> createState() =>
      _AdminEntityModerationScreenState();
}

class _AdminEntityModerationScreenState
    extends State<AdminEntityModerationScreen>
    with SingleTickerProviderStateMixin {
  final _repository = AdminRepository();
  late final TabController _tabController;
  late Future<List<AdminModeratableEntity>> _pendingFuture;
  late Future<List<AdminModeratableEntity>> _publishedFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _pendingFuture = _repository.getPendingEntities();
    _publishedFuture = _repository.getPublishedEntities();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _pendingFuture = _repository.getPendingEntities();
      _publishedFuture = _repository.getPublishedEntities();
    });
  }

  String _kindLabel(String kind) =>
      kind == 'service' ? 'Service' : 'Figure publique';

  Future<void> _approve(AdminModeratableEntity item) async {
    await _repository.approveEntity(item.id);
    _reload();
  }

  Future<void> _reject(AdminModeratableEntity item) async {
    final confirmed = await _confirm(
      title: 'Rejeter cette publication ?',
      message: '"${item.name}" restera masquée du public (statut rejeté).',
      confirmLabel: 'Rejeter',
    );
    if (confirmed) {
      await _repository.rejectEntity(item.id);
      _reload();
    }
  }

  Future<void> _delete(AdminModeratableEntity item) async {
    final confirmed = await _confirm(
      title: 'Supprimer définitivement ?',
      message: '"${item.name}" sera supprimée définitivement, avec ses avis et '
          'commentaires. Cette action est irréversible.',
      confirmLabel: 'Supprimer',
    );
    if (confirmed) {
      await _repository.deleteEntity(item.id);
      _reload();
    }
  }

  Future<bool> _confirm(
      {required String title,
      required String message,
      required String confirmLabel}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: Text(confirmLabel)),
        ],
      ),
    );
    return confirmed == true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modération des publications'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryOrange,
          indicatorColor: AppColors.primaryOrange,
          tabs: const [
            Tab(text: 'En attente'),
            Tab(text: 'Publiées'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _EntityList(
            future: _pendingFuture,
            kindLabel: _kindLabel,
            emptyLabel: 'Aucune publication en attente d\'approbation.',
            buildActions: (item) => [
              TextButton(
                onPressed: () => _reject(item),
                child:
                    const Text('Rejeter', style: TextStyle(color: Colors.red)),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange),
                onPressed: () => _approve(item),
                child: const Text('Approuver'),
              ),
            ],
          ),
          _EntityList(
            future: _publishedFuture,
            kindLabel: _kindLabel,
            emptyLabel: 'Aucune publication en ligne pour le moment.',
            buildActions: (item) => [
              TextButton(
                onPressed: () => _delete(item),
                child: const Text('Supprimer',
                    style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EntityList extends StatelessWidget {
  final Future<List<AdminModeratableEntity>> future;
  final String Function(String kind) kindLabel;
  final String emptyLabel;
  final List<Widget> Function(AdminModeratableEntity item) buildActions;

  const _EntityList({
    required this.future,
    required this.kindLabel,
    required this.emptyLabel,
    required this.buildActions,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AdminModeratableEntity>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return Center(
            child: Text(emptyLabel,
                style: const TextStyle(color: AppColors.textSecondary)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = items[index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.imageUrl,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 56,
                            height: 56,
                            color: AppColors.surfaceChip,
                            child: const Icon(Icons.image_not_supported,
                                color: AppColors.iconInactive),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            Text(
                              '${kindLabel(item.kind)} · ${item.creatorName}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (item.description != null &&
                      item.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(item.description!,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: buildActions(item),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
