import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/icon_resolver.dart';

/// Grand bouton encadré utilisé sur l'écran d'accueil "Évaluer" —
/// icône à gauche, libellé centré, toute la carte est cliquable.
class EvaluerCategoryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// AJOUT — optionnel, ne change rien si non fourni. Si renseigné et
  /// qu'un SVG du même nom existe dans assets/icons/, il remplace
  /// [icon] ; sinon [icon] reste affichée normalement, comme avant.
  final String? iconValue;

  const EvaluerCategoryButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconValue,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider, width: 1.4),
        ),
        child: Row(
          children: [
            iconValue != null
                ? resolveEntityIcon(
                    iconValue: iconValue,
                    fallback: icon,
                    size: 44,
                    color: AppColors.iconDefault,
                  )
                : Icon(icon, size: 44, color: AppColors.iconDefault),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 44), // équilibre visuel avec l'icône à gauche
          ],
        ),
      ),
    );
  }
}
