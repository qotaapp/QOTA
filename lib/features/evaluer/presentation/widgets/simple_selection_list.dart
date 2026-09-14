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
  late List<SelectionItem> _filteredItems;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items.where((item) {
          return item.label.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
                    : _filteredItems.isEmpty
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
                            itemCount: _filteredItems.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = _filteredItems[index];
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
