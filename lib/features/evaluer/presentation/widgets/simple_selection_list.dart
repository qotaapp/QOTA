import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/icon_resolver.dart';

/// Liste simple réutilisée pour États / Villes / Zones / Catégories —
/// affichée sous forme de boutons (carte + icône), reste dans l'esprit
/// "extrêmement simple" imposé pour toute l'interface (§11).
class SimpleSelectionList extends StatefulWidget {
  final String title;
  final String? subtitle;
  final List<SelectionItem> items;
  final ValueChanged<SelectionItem> onSelect;
  final bool isLoading;

  /// Icône par défaut utilisée quand un item n'a pas d'icône propre en
  /// base (`SelectionItem.icon` null/vide) — spécifique à chaque écran
  /// appelant (ville, zone, catégorie...).
  final IconData fallbackIcon;

  const SimpleSelectionList({
    super.key,
    required this.title,
    required this.items,
    required this.onSelect,
    this.isLoading = false,
    this.subtitle,
    this.fallbackIcon = Icons.place_outlined,
  });

  @override
  State<SimpleSelectionList> createState() => _SimpleSelectionListState();
}

class _SimpleSelectionListState extends State<SimpleSelectionList> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _searchController.text.toLowerCase().trim();
    if (q == _searchQuery) return; // évite les setState inutiles
    setState(() => _searchQuery = q);
  }

  /// Calculé à la volée → toujours synchronisé avec `widget.items`,
  /// peu importe comment / quand le parent met à jour la liste.
  List<SelectionItem> get _visibleItems {
    if (_searchQuery.isEmpty) return widget.items;
    return widget.items
        .where((item) => item.label.toLowerCase().contains(_searchQuery))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleItems;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          if (widget.subtitle != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.subtitle!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Chercher...',
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.iconInactive),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: AppColors.iconInactive),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: widget.isLoading
                ? const Center(child: CircularProgressIndicator())
                : widget.items.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucun élément disponible',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : visible.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'Aucun résultat pour "$_searchQuery"',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: AppColors.textSecondary),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                            itemCount: visible.length,
                            itemBuilder: (context, index) {
                              final item = visible[index];
                              return _SelectionButton(
                                item: item,
                                fallbackIcon: widget.fallbackIcon,
                                onTap: () => widget.onSelect(item),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

/// Bouton individuel — carte arrondie, icône à gauche (dynamique si
/// fournie par la base, sinon icône générique du contexte), libellé,
/// chevron à droite. Remplace l'ancien ListTile en ligne simple.
class _SelectionButton extends StatelessWidget {
  final SelectionItem item;
  final IconData fallbackIcon;
  final VoidCallback onTap;

  const _SelectionButton({
    required this.item,
    required this.fallbackIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider, width: 1.2),
            ),
            child: Row(
              children: [
                resolveEntityIcon(
                  iconValue: item.icon,
                  fallback: fallbackIcon,
                  size: 22,
                  color: AppColors.iconDefault,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    item.label,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.iconInactive,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SelectionItem {
  final String id;
  final String label;
  final String? icon;
  const SelectionItem({required this.id, required this.label, this.icon});
}
