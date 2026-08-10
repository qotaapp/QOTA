import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// §11 du cahier des charges :
/// - Philosophie visuelle extrêmement simple.
/// - 5 icônes : Home, Évaluer (⭐), Notifications, Profile, Menu.
/// - AUCUN texte sous les icônes.
/// - L'icône Évaluer est une étoile unique, même taille/style que les autres.
///
/// Un simple point orange indique des notifications non lues (§38) —
/// reste minimal, ne casse pas la philosophie "extrêmement simple".
class MainBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool hasUnreadNotifications;

  const MainBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.hasUnreadNotifications = false,
  });

  static const double _iconSize = 26;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavIcon(
                isActive: currentIndex == 0,
                icon: Icons.home_outlined,
                activeIcon: Icons.home_filled,
                onTap: () => onTap(0),
              ),
              _NavIcon(
                isActive: currentIndex == 1,
                // Icône Évaluer : une seule étoile, même taille que les autres icônes.
                icon: Icons.star_border_rounded,
                activeIcon: Icons.star_rounded,
                activeColor: AppColors.starFilled,
                onTap: () => onTap(1),
              ),
              _NavIcon(
                isActive: currentIndex == 2,
                icon: Icons.notifications_none_rounded,
                activeIcon: Icons.notifications_rounded,
                showBadge: hasUnreadNotifications,
                onTap: () => onTap(2),
              ),
              _NavIcon(
                isActive: currentIndex == 3,
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                onTap: () => onTap(3),
              ),
              _NavIcon(
                isActive: currentIndex == 4,
                icon: Icons.menu_rounded,
                activeIcon: Icons.menu_rounded,
                onTap: () => onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final bool isActive;
  final IconData icon;
  final IconData activeIcon;
  final Color? activeColor;
  final VoidCallback onTap;
  final bool showBadge;

  const _NavIcon({
    required this.isActive,
    required this.icon,
    required this.activeIcon,
    required this.onTap,
    this.activeColor,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: MainBottomNav._iconSize,
              color: isActive
                  ? (activeColor ?? AppColors.iconDefault)
                  : AppColors.iconInactive,
            ),
            if (showBadge)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryOrange,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
