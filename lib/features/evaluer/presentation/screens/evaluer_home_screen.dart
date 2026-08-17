import 'package:flutter/material.dart';
import '../widgets/evaluer_category_button.dart';
import 'evaluer_screen.dart';
import 'coming_soon_screen.dart';
import '../../../figures/presentation/screens/figure_type_list_screen.dart';

/// Nouveau point d'entrée de l'onglet ⭐ Évaluer — menu de catégories,
/// chacune menant vers son propre parcours.
class EvaluerHomeScreen extends StatelessWidget {
  const EvaluerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Évaluer')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            // §13-22 : parcours État -> Ville/Zone -> Catégorie -> Services,
            // déjà entièrement construit dans EvaluerScreen.
            EvaluerCategoryButton(
              icon: Icons.location_searching_rounded,
              label: 'Recherche par état',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EvaluerScreen()),
              ),
            ),
            // §35-37 : Figures Publiques, déjà entièrement construites.
            EvaluerCategoryButton(
              icon: Icons.workspace_premium_outlined,
              label: 'Personnages publique',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FigureTypeListScreen()),
              ),
            ),
            // À développer ultérieurement.
            EvaluerCategoryButton(
              icon: Icons.live_tv_outlined,
              label: 'Chaînes et programmes',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      const ComingSoonScreen(title: 'Chaînes et programmes'),
                ),
              ),
            ),
            EvaluerCategoryButton(
              icon: Icons.shopping_cart_outlined,
              label: 'Vente en ligne',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      const ComingSoonScreen(title: 'Vente en ligne'),
                ),
              ),
            ),
            EvaluerCategoryButton(
              icon: Icons.inventory_2_outlined,
              label: 'Autres',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ComingSoonScreen(title: 'Autres'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
