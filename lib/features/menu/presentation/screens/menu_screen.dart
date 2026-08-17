import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../wallet/presentation/screens/wallet_screen.dart';
import '../../../admin/data/admin_repository.dart';
import '../../../admin/presentation/screens/admin_home_screen.dart';
import '../../../auth/data/auth_repository.dart';

/// Menu : accès au Wallet, Dashboard Super Admin (visible uniquement
/// pour ce rôle), déconnexion. Les Figures Publiques sont accessibles
/// depuis l'onglet ⭐ Évaluer (bouton "Personnages publique").
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => MenuScreenState();
}

/// État public (pas de préfixe _) pour permettre à RootShell de
/// déclencher un rafraîchissement du rôle via GlobalKey — sans ça,
/// IndexedStack garde cet écran en mémoire et ne revérifie le rôle
/// qu'une seule fois, à la toute première ouverture de l'app.
class MenuScreenState extends State<MenuScreen> {
  final _adminRepository = AdminRepository();
  bool _isSuperAdmin = false;

  @override
  void initState() {
    super.initState();
    refreshAdminStatus();
  }

  Future<void> refreshAdminStatus() async {
    final isAdmin = await _adminRepository.isCurrentUserSuperAdmin();
    if (mounted) setState(() => _isSuperAdmin = isAdmin);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text('Menu',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined,
                color: AppColors.iconDefault),
            title: const Text('Mon Wallet — Qota Coin'),
            trailing: const Icon(Icons.chevron_right_rounded,
                color: AppColors.iconInactive),
            onTap: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const WalletScreen()));
            },
          ),
          const Divider(height: 1),
          if (_isSuperAdmin) ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined,
                  color: AppColors.primaryOrange),
              title: const Text('Dashboard Super Admin',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: AppColors.iconInactive),
              onTap: () {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminHomeScreen()));
              },
            ),
          ],
          const Divider(height: 1),
          ListTile(
            leading:
                const Icon(Icons.logout_rounded, color: AppColors.iconDefault),
            title: const Text('Déconnexion'),
            onTap: () async {
              await AuthRepository().signOut();
            },
          ),
        ],
      ),
    );
  }
}
