import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Liste simple réutilisée pour États / Villes / Zones — reste dans
/// l'esprit "extrêmement simple" imposé pour toute l'interface (§11).
class SimpleSelectionList extends StatelessWidget {
  final String title;
  final List<SelectionItem> items;
  final ValueChanged<SelectionItem> onSelect;
  final bool isLoading;

  const SimpleSelectionList({
    super.key,
    required this.title,
    required this.items,
    required this.onSelect,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? const Center(child: Text('Aucun élément disponible', style: TextStyle(color: AppColors.textSecondary)))
              : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      title: Text(item.label),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.iconInactive),
                      onTap: () => onSelect(item),
                    );
                  },
                ),
    );
  }
}

class SelectionItem {
  final String id;
  final String label;
  const SelectionItem({required this.id, required this.label});
}
