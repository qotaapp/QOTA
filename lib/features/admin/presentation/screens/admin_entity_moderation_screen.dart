import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  /// Ouvre le formulaire de modification (nom / description / photo)
  /// AVANT approbation — permet au Super Admin de corriger une
  /// publication plutôt que de devoir la rejeter.
  Future<void> _openEdit(AdminModeratableEntity item) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _EditEntityScreen(entity: item),
      ),
    );
    if (changed == true) {
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
              // Modification autorisée uniquement AVANT approbation —
              // pour une publication déjà publiée, on préfère forcer
              // une suppression explicite plutôt qu'une édition
              // silencieuse d'un contenu déjà visible du public.
              TextButton(
                onPressed: () => _openEdit(item),
                child: const Text('Modifier'),
              ),
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

/// Formulaire de modification d'une publication en attente —
/// nom, description, photo. Le Super Admin doit ensuite revenir sur
/// la liste et taper "Approuver" séparément : modifier n'approuve
/// jamais automatiquement, pour garder les deux actions distinctes
/// et volontaires.
class _EditEntityScreen extends StatefulWidget {
  final AdminModeratableEntity entity;

  const _EditEntityScreen({required this.entity});

  @override
  State<_EditEntityScreen> createState() => _EditEntityScreenState();
}

class _EditEntityScreenState extends State<_EditEntityScreen> {
  final _repository = AdminRepository();
  final _picker = ImagePicker();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  XFile? _pickedImage;
  String? _currentImageUrl;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.entity.name);
    _descriptionController =
        TextEditingController(text: widget.entity.description ?? '');
    _currentImageUrl = widget.entity.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null) {
      setState(() => _pickedImage = image);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Le nom est obligatoire.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      String? newImageUrl;
      if (_pickedImage != null) {
        final bytes = await _pickedImage!.readAsBytes();
        final extension = _pickedImage!.name.split('.').last;
        newImageUrl = await _repository.uploadEntityImage(
            bytes: bytes, fileExtension: extension);
      }

      await _repository.updateEntityDetails(
        entityId: widget.entity.id,
        name: name,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        imageUrl: newImageUrl,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _errorMessage = 'Impossible d\'enregistrer les modifications.';
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier la publication')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceChip,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_pickedImage != null)
                        Image.file(File(_pickedImage!.path), fit: BoxFit.cover)
                      else if (_currentImageUrl != null)
                        Image.network(_currentImageUrl!, fit: BoxFit.cover)
                      else
                        const Center(
                          child: Icon(Icons.add_a_photo_outlined,
                              size: 32, color: AppColors.iconInactive),
                        ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryOrange,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt_rounded,
                              size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description (optionnel)',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
