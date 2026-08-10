import 'package:flutter/material.dart';
import '../../features/navigation/presentation/widgets/main_bottom_nav.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/evaluer/presentation/screens/evaluer_screen.dart';
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

  static const _screens = [
    HomeScreen(),
    EvaluerScreen(),
    NotificationsScreen(),
    ProfileScreen(),
    MenuScreen(),
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
