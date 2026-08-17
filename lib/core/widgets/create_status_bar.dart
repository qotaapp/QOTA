import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';

/// Barre "Qu'allons-nous évaluer ?" — permet de créer et publier un
/// statut (User Item). Utilisée à l'identique sur le Profil et la Home
/// pour que l'action de publication soit accessible partout.
class CreateStatusBar extends StatelessWidget {
  final String? avatarUrl;
  final VoidCallback onTap;
  final String label;

  const CreateStatusBar({
    super.key,
    required this.avatarUrl,
    required this.onTap,
    this.label = 'Qu\'allons-nous évaluer ?',
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceChip,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              backgroundImage: avatarUrl != null
                  ? CachedNetworkImageProvider(avatarUrl!)
                  : null,
              child: avatarUrl == null
                  ? const Icon(
                      Icons.person,
                      size: 18,
                      color: AppColors.iconInactive,
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: AppColors.textSecondary),
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
    );
  }
}
