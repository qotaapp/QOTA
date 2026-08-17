import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
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
  late Future<_ProfileData> _futureData;
  bool _hideBalance = false;

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
                        InkWell(
                          onTap: _openAddUserItem,
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceChip,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.white,
                                  backgroundImage: profile.avatarUrl != null
                                      ? CachedNetworkImageProvider(
                                          profile.avatarUrl!)
                                      : null,
                                  child: profile.avatarUrl == null
                                      ? const Icon(
                                          Icons.person,
                                          size: 18,
                                          color: AppColors.iconInactive,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'Qu\'allons-nous évaluer ?',
                                    style: TextStyle(
                                        color: AppColors.textSecondary),
                                  ),
                                ),
                                const Icon(
                                  Icons.add_photo_alternate_outlined,
                                  color: AppColors.iconInactive,
                                ),
                                const SizedBox(width: 4),
                              ],
                            ),
                          ),
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
                          item: item,
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
                          onOpenImageFullscreen: () =>
                              Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => FullscreenImageViewer(
                                  imageUrl: item.imageUrl),
                            ),
                          ),
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
