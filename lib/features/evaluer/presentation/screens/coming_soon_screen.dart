import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Écran temporaire pour une catégorie Évaluer pas encore développée.
/// À remplacer par l'implémentation réelle quand elle sera construite.
class ComingSoonScreen extends StatelessWidget {
  final String title;

  const ComingSoonScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hourglass_empty_rounded,
                  size: 40, color: AppColors.iconInactive),
              SizedBox(height: 12),
              Text(
                'Bientôt disponible',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
