import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/admin_repository.dart';
import 'admin_states_screen.dart';
import 'admin_categories_screen.dart';
import 'admin_ownership_requests_screen.dart';
import 'admin_coin_purchases_screen.dart';
import 'admin_geography_screen.dart';
import 'admin_entity_moderation_screen.dart';
import 'admin_moderators_screen.dart';
import 'admin_bon_plans_screen.dart';

/// Dashboard — point d'entrée unique vers la gestion dynamique de la
/// plateforme (§14, §16, §20, §22, §3), désormais accessible aussi
/// aux modérateurs : chacun ne voit QUE les sections couvertes par
/// son rôle bien déterminé (permissions accordées par le Super Admin).
/// Le Super Admin voit toujours tout.
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final _repository = AdminRepository();
  late Future<_AdminAccess> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadAccess();
  }

  Future<_AdminAccess> _loadAccess() async {
    final isSuperAdmin = await _repository.isCurrentUserSuperAdmin();
    final permissions = isSuperAdmin
        ? <String>{}
        : await _repository.getMyModeratorPermissions();
    return _AdminAccess(isSuperAdmin: isSuperAdmin, permissions: permissions);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: FutureBuilder<_AdminAccess>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final access = snapshot.data!;

          final sections = <_AdminSection>[
            if (access.isSuperAdmin)
              _AdminSection(
                icon: Icons.map_outlined,
                title: 'États',
                subtitle: 'Gouvernorats, traductions, activation',
                builder: (_) => const AdminStatesScreen(),
              ),
            if (access.isSuperAdmin ||
                access.permissions.contains('manage_geography'))
              _AdminSection(
                icon: Icons.location_city_outlined,
                title: 'Villes & Zones',
                subtitle: 'Créer, modifier, supprimer',
                builder: (_) => const AdminGeographyScreen(),
              ),
            if (access.isSuperAdmin)
              _AdminSection(
                icon: Icons.category_outlined,
                title: 'Catégories',
                subtitle: 'Créer, traduire, réordonner, désactiver',
                builder: (_) => const AdminCategoriesScreen(),
              ),
            if (access.isSuperAdmin ||
                access.permissions.contains('moderate_content'))
              _AdminSection(
                icon: Icons.rate_review_outlined,
                title: 'Modération des publications',
                subtitle: 'Approuver, rejeter ou supprimer Services & Figures',
                builder: (_) => const AdminEntityModerationScreen(),
              ),
            if (access.isSuperAdmin)
              _AdminSection(
                icon: Icons.verified_outlined,
                title: 'Demandes de propriété',
                subtitle: 'Approuver ou refuser les transferts de Service',
                builder: (_) => const AdminOwnershipRequestsScreen(),
              ),
            if (access.isSuperAdmin)
              _AdminSection(
                icon: Icons.monetization_on_outlined,
                title: 'Achats Qota Coin',
                subtitle: 'Valider les demandes de crédit',
                builder: (_) => const AdminCoinPurchasesScreen(),
              ),
            if (access.isSuperAdmin)
              _AdminSection(
                icon: Icons.local_offer_outlined,
                title: 'Bons plans',
                subtitle: 'Publier les offres affichées côté utilisateur',
                builder: (_) => const AdminBonPlansScreen(),
              ),
            if (access.isSuperAdmin)
              _AdminSection(
                icon: Icons.shield_outlined,
                title: 'Modérateurs',
                subtitle: 'Désigner des modérateurs à rôle déterminé',
                builder: (_) => const AdminModeratorsScreen(),
              ),
          ];

          return SafeArea(
            child: ListView.separated(
              itemCount: sections.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final section = sections[index];
                return ListTile(
                  leading: Icon(section.icon, color: AppColors.iconDefault),
                  title: Text(section.title),
                  subtitle: Text(section.subtitle,
                      style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: AppColors.iconInactive),
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: section.builder)),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _AdminAccess {
  final bool isSuperAdmin;
  final Set<String> permissions;

  _AdminAccess({required this.isSuperAdmin, required this.permissions});
}

class _AdminSection {
  final IconData icon;
  final String title;
  final String subtitle;
  final WidgetBuilder builder;

  _AdminSection(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.builder});
}
