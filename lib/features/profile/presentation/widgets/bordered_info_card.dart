import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Boîte encadrée réutilisée pour le header profil, "mon Qota" et
/// "Qota coin" — donne le look "carte bien délimitée" de la maquette.
class BorderedInfoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const BorderedInfoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 1.4),
      ),
      child: child,
    );
  }
}
