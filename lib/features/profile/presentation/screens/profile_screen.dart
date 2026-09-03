import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/create_status_bar.dart';
import '../../data/profile_models.dart';
import '../../data/profile_repository.dart';
import '../widgets/bordered_info_card.dart';
import '../widgets/user_item_post_card.dart';
import 'add_user_item_screen.dart';
import '../../../evaluer/presentation/screens/fullscreen_image_viewer.dart';
import '../../../rating/presentation/widgets/rating_sheet.dart';
import '../../../comments/presentation/screens/comments_screen.dart';
import '../../../wallet/presentation/screens/wallet_screen.dart';

/// §7 : profil public — photo, nom, prénom, User Items publiés.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _repository = ProfileRepository();
  final _picker = ImagePicker();
  late Future<_ProfileData> _futureData;
  bool _hideBalance = true;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _futureData = _load();
  }

  Future<_ProfileData> _load() async {
    final profile = await _repository.getMyProfile();
    final items = await _repository.getUserItems(profile.id);
    final balance = await _repository.getMyWalletBalance();
    return _ProfileData(profile: profile, items: items, walletBalance: balance);
  }

  void _reload() {
    setState(() => _futureData = _load());
  }

  /// §8 : 1er changement gratuit, ensuite payant (Qota Coin).
  /// Le compteur et le débit sont gérés côté serveur (RPC), jamais côté client.
  Future<void> _openEditNameDialog(QotaProfile profile) async {
    final firstNameController = TextEditingController(text: profile.firstName);
    final lastNameController = TextEditingController(text: profile.lastName);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le nom'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (profile.nameChangeCount >= 1)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Vous avez déjà utilisé votre changement de nom gratuit. '
                  'Ce changement sera débité de votre solde Qota Coin.',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
            TextField(
              controller: lastNameController,
              decoration: const InputDecoration(labelText: 'Nom'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: firstNameController,
              decoration: const InputDecoration(labelText: 'Prénom'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    final result = await _repository.changeName(
      firstName: firstNameController.text.trim(),
      lastName: lastNameController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    if (result['status'] == 'insufficient_funds') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Solde Qota Coin insuffisant (${result['price']} requis). '
            'Rechargez votre wallet.',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['charged'] == true
              ? 'Nom modifié — débité de votre wallet.'
              : 'Nom modifié avec succès.',
        ),
      ),
    );
    _reload();
  }

  Future<void> _openAddUserItem() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddUserItemScreen()),
    );
    if (created == true) {
      _reload();
    }
  }

  /// Photo de profil : redimensionnée dès la sélection (max 640x640,
  /// qualité 85) pour rester légère et nette une fois recadrée en
  /// cercle — y compris dans les petits avatars (barre de statut, etc.).
  Future<void> _changeAvatar() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 640,
      maxHeight: 640,
      imageQuality: 85,
    );
    if (image == null) {
      return;
    }

    setState(() => _isUploadingAvatar = true);
    try {
      final bytes = await image.readAsBytes();
      final extension = image.name.split('.').last;
      final avatarUrl = await _repository.uploadAvatarImage(
          bytes: bytes, fileExtension: extension);
      await _repository.updateAvatarUrl(avatarUrl);
      _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Impossible de mettre à jour la photo. Réessayez.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  /// Suppression d'une de SES PROPRES publications — le profil
  /// personnel n'affiche jamais que les User Items de l'utilisateur
  /// connecté (getUserItems(profile.id) où profile = getMyProfile()),
  /// donc onDelete est toujours sûr à proposer ici, pour tous les
  /// utilisateurs, sans vérification de rôle supplémentaire.
  Future<void> _deleteItem(QotaUserItem item) async {
    await _repository.deleteUserItem(item.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Publication supprimée.')),
      );
      _reload();
    }
  }

  /// "mon Qota" : moyenne des évaluations reçues sur l'ensemble des
  /// User Items du profil (calculée côté client à partir des moyennes
  /// déjà agrégées par item — pas de nouvelle requête serveur requise).
  double? _averageAcrossItems(List<QotaUserItem> items) {
    final rated = items.where((i) => i.ratingsCount > 0).toList();
    if (rated.isEmpty) {
      return null;
    }
    final sum = rated.fold<double>(0, (acc, i) => acc + i.averageScore);
    return sum / rated.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: SafeArea(
        child: FutureBuilder<_ProfileData>(
          future: _futureData,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data!;
            final profile = data.profile;
            final averageScore = _averageAcrossItems(data.items);

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      children: [
                        // ---- Carte identité ----
                        BorderedInfoCard(
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap:
                                    _isUploadingAvatar ? null : _changeAvatar,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    CircleAvatar(
                                      radius: 34,
                                      backgroundColor: AppColors.surfaceChip,
                                      backgroundImage: profile.avatarUrl != null
                                          ? CachedNetworkImageProvider(
                                              profile.avatarUrl!)
                                          : null,
                                      child: profile.avatarUrl == null
                                          ? const Icon(
                                              Icons.person,
                                              size: 34,
                                              color: AppColors.iconInactive,
                                            )
                                          : null,
                                    ),
                                    if (_isUploadingAvatar)
                                      const Positioned.fill(
                                        child: CircleAvatar(
                                          backgroundColor: Colors.black38,
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      Positioned(
                                        right: -2,
                                        bottom: -2,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: AppColors.primaryOrange,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: Colors.white, width: 2),
                                          ),
                                          child: const Icon(
                                            Icons.camera_alt,
                                            size: 12,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  profile.fullName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _openEditNameDialog(profile),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ---- Carte "mon Qota" ----
                        BorderedInfoCard(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 40,
                                color: AppColors.starFilled,
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    averageScore == null
                                        ? '—'
                                        : averageScore.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.starFilled,
                                    ),
                                  ),
                                  const Text(
                                    'mon Qota',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ---- Carte "Qota coin" ----
                        BorderedInfoCard(
                          child: InkWell(
                            onTap: () => Navigator.of(context)
                                .push(MaterialPageRoute(
                                    builder: (_) => const WalletScreen()))
                                .then((_) => _reload()),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.monetization_on_rounded,
                                  size: 40,
                                  color: AppColors.primaryOrange,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _hideBalance
                                            ? '••••'
                                            : data.walletBalance
                                                .toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primaryOrange,
                                        ),
                                      ),
                                      const Text(
                                        'Qota coin',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    _hideBalance
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppColors.iconInactive,
                                  ),
                                  onPressed: () => setState(
                                      () => _hideBalance = !_hideBalance),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ---- Barre "Qu'allons-nous évaluer ?" ----
                        CreateStatusBar(
                          avatarUrl: profile.avatarUrl,
                          onTap: _openAddUserItem,
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                if (data.items.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'Aucun User Item publié pour le moment',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = data.items[index];
                        return UserItemPostCard(
                          itemId: item.id,
                          name: item.name,
                          description: item.description,
                          imageUrl: item.imageUrl,
                          ownerId: item.ownerId,
                          ownerName: item.ownerName,
                          ownerAvatarUrl: item.ownerAvatarUrl,
                          createdAt: item.createdAt,
                          averageScore: item.averageScore,
                          ratingsCount: item.ratingsCount,
                          commentsCount: item.commentsCount,
                          viewsCount: item.viewsCount,
                          // MODIF : sur SON PROPRE profil, tout
                          // utilisateur peut supprimer ses publications
                          // — affiche le menu ⋮ -> "Supprimer" déjà
                          // prévu dans UserItemPostCard.
                          onDelete: () => _deleteItem(item),
                          onOpenRatingSheet: () => RatingSheet.show(
                            context,
                            entityId: item.id,
                            onSubmitted: _reload,
                          ),
                          onOpenComments: () => Navigator.of(context)
                              .push(MaterialPageRoute(
                                builder: (_) => CommentsScreen(
                                  entityId: item.id,
                                  entityKind: 'user_item',
                                  entityOwnerId: profile.id, // §34
                                ),
                              ))
                              .then((_) => _reload()),
                          onOpenImageFullscreen: () => Navigator.of(context)
                              .push(
                                MaterialPageRoute(
                                  builder: (_) => FullscreenImageViewer(
                                      imageUrl: item.imageUrl),
                                ),
                              )
                              // Recharge pour refléter le nombre de
                              // vues mis à jour côté base (RPC
                              // increment_entity_views, §023) — sinon
                              // le chiffre affiché reste figé.
                              .then((_) => _reload()),
                        );
                      },
                      childCount: data.items.length,
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProfileData {
  final QotaProfile profile;
  final List<QotaUserItem> items;
  final double walletBalance;

  _ProfileData({
    required this.profile,
    required this.items,
    required this.walletBalance,
  });
}
