import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/profile_models.dart';
import '../../data/profile_repository.dart';
import '../widgets/user_item_card.dart';
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
                decoration: const InputDecoration(labelText: 'Nom')),
            const SizedBox(height: 8),
            TextField(
                controller: firstNameController,
                decoration: const InputDecoration(labelText: 'Prénom')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmer')),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await _repository.changeName(
      firstName: firstNameController.text.trim(),
      lastName: lastNameController.text.trim(),
    );

    if (!mounted) return;

    if (result['status'] == 'insufficient_funds') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
          'Solde Qota Coin insuffisant (${result['price']} requis). Rechargez votre wallet.',
        )),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
        result['charged'] == true
            ? 'Nom modifié — débité de votre wallet.'
            : 'Nom modifié avec succès.',
      )),
    );
    _reload();
  }

  Future<void> _openAddUserItem() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddUserItemScreen()),
    );
    if (created == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<_ProfileData>(
          future: _futureData,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data!;
            final profile = data.profile;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: AppColors.surfaceChip,
                          backgroundImage: profile.avatarUrl != null
                              ? CachedNetworkImageProvider(profile.avatarUrl!)
                              : null,
                          child: profile.avatarUrl == null
                              ? const Icon(Icons.person,
                                  size: 44, color: AppColors.iconInactive)
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(profile.fullName,
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.w800)),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () => _openEditNameDialog(profile),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () => Navigator.of(context)
                              .push(MaterialPageRoute(
                                  builder: (_) => const WalletScreen()))
                              .then((_) => _reload()),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.monetization_on_outlined,
                                  size: 18, color: AppColors.primaryOrange),
                              const SizedBox(width: 4),
                              Text(
                                  '${data.walletBalance.toStringAsFixed(0)} Qota Coin',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(width: 2),
                              const Icon(Icons.chevron_right_rounded,
                                  size: 16, color: AppColors.iconInactive),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _openAddUserItem,
                            icon:
                                const Icon(Icons.add_photo_alternate_outlined),
                            label: const Text('Publier un User Item'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Mes User Items',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 16)),
                        ),
                      ],
                    ),
                  ),
                ),
                if (data.items.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text('Aucun User Item publié pour le moment',
                            style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = data.items[index];
                        return UserItemCard(
                          item: item,
                          onOpenRatingSheet: () => RatingSheet.show(context,
                              entityId: item.id, onSubmitted: _reload),
                          onOpenComments: () => Navigator.of(context)
                              .push(MaterialPageRoute(
                                builder: (_) => CommentsScreen(
                                  entityId: item.id,
                                  entityKind: 'user_item',
                                  entityOwnerId: profile
                                      .id, // §34 : droit de suppression étendu
                                ),
                              ))
                              .then((_) => _reload()),
                          onOpenImageFullscreen: () =>
                              Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => FullscreenImageViewer(
                                    imageUrl: item.imageUrl)),
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

  _ProfileData(
      {required this.profile,
      required this.items,
      required this.walletBalance});
}
