import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'admin_states_screen.dart';
import 'admin_categories_screen.dart';
import 'admin_ownership_requests_screen.dart';
import 'admin_coin_purchases_screen.dart';

/// Dashboard Super Admin — point d'entrée unique vers la gestion
/// dynamique de la plateforme (§14, §16, §20, §22, §3). Accessible
/// uniquement aux utilisateurs ayant le rôle 'super_admin'.
class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = <_AdminSection>[
      _AdminSection(
        icon: Icons.map_outlined,
        title: 'États',
        subtitle: 'Gouvernorats, traductions, activation',
        builder: (_) => const AdminStatesScreen(),
      ),
      _AdminSection(
        icon: Icons.category_outlined,
        title: 'Catégories',
        subtitle: 'Créer, traduire, réordonner, désactiver',
        builder: (_) => const AdminCategoriesScreen(),
      ),
      _AdminSection(
        icon: Icons.verified_outlined,
        title: 'Demandes de propriété',
        subtitle: 'Approuver ou refuser les transferts de Service',
        builder: (_) => const AdminOwnershipRequestsScreen(),
      ),
      _AdminSection(
        icon: Icons.monetization_on_outlined,
        title: 'Achats Qota Coin',
        subtitle: 'Valider les demandes de crédit',
        builder: (_) => const AdminCoinPurchasesScreen(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Super Admin')),
      body: SafeArea(
        child: ListView.separated(
          itemCount: sections.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final section = sections[index];
            return ListTile(
              leading: Icon(section.icon, color: AppColors.iconDefault),
              title: Text(section.title),
              subtitle: Text(section.subtitle, style: const TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.iconInactive),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: section.builder)),
            );
          },
        ),
      ),
    );
  }
}

class _AdminSection {
  final IconData icon;
  final String title;
  final String subtitle;
  final WidgetBuilder builder;

  _AdminSection({required this.icon, required this.title, required this.subtitle, required this.builder});
}
