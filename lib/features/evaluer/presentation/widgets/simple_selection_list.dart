import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Liste simple réutilisée pour États / Villes / Zones — reste dans
/// l'esprit "extrêmement simple" imposé pour toute l'interface (§11).
class SimpleSelectionList extends StatefulWidget {
  final String title;
  final String? subtitle;
  final List<SelectionItem> items;
  final ValueChanged<SelectionItem> onSelect;
  final bool isLoading;

  const SimpleSelectionList({
    super.key,
    required this.title,
    required this.items,
    required this.onSelect,
    this.isLoading = false,
    this.subtitle,
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
                        : ListView.separated(
                            itemCount: visible.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = visible[index];
                              return ListTile(
                                title: Text(item.label),
                                trailing: const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.iconInactive,
                                ),
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

class SelectionItem {
  final String id;
  final String label;
  const SelectionItem({required this.id, required this.label});
}
