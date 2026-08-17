import 'package:flutter/material.dart';
import '../../features/navigation/presentation/widgets/main_bottom_nav.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/evaluer/presentation/screens/evaluer_home_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/notifications/data/notifications_repository.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/menu/presentation/screens/menu_screen.dart';

/// Conteneur racine : bascule entre les 5 sections principales via
/// MainBottomNav, sans jamais faire apparaître de texte sous les icônes.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;
  final _notificationsRepository = NotificationsRepository();
  bool _hasUnread = false;

  // GlobalKey sur MenuScreen : IndexedStack garde chaque écran en
  // mémoire en permanence (pour ne pas perdre leur état au changement
  // d'onglet), donc son initState() ne s'exécute qu'une seule fois.
  // Sans ce mécanisme, un rôle Super Admin ajouté après la connexion
  // ne serait jamais détecté tant que l'app n'est pas relancée.
  final _menuKey = GlobalKey<MenuScreenState>();

  late final List<Widget> _screens = [
    const HomeScreen(),
    const EvaluerHomeScreen(),
    const NotificationsScreen(),
    const ProfileScreen(),
    MenuScreen(key: _menuKey),
  ];

  @override
  void initState() {
    super.initState();
    _refreshUnreadStatus();
  }

  Future<void> _refreshUnreadStatus() async {
    final count = await _notificationsRepository.getUnreadCount();
    if (mounted) setState(() => _hasUnread = count > 0);
  }

  void _onTap(int index) {
    setState(() => _index = index);
    if (index == 2) {
      // En quittant l'onglet Notifications, le badge se rafraîchit
      // (les notifications viennent d'être marquées lues dans l'écran).
      Future.delayed(const Duration(milliseconds: 300), _refreshUnreadStatus);
    }
    if (index == 4) {
      // Revérifie le rôle Super Admin à CHAQUE ouverture du Menu, pas
      // seulement à la connexion (voir commentaire sur _menuKey).
      _menuKey.currentState?.refreshAdminStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: MainBottomNav(
        currentIndex: _index,
        onTap: _onTap,
        hasUnreadNotifications: _hasUnread,
      ),
    );
  }
}
