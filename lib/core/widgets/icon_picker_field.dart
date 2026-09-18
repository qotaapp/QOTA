import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'icon_resolver.dart';

/// Champ de formulaire pour choisir l'icône d'une entité gérée par le
/// Super Admin (catégorie, et plus tard ville/zone) parmi les SVG
/// disponibles dans assets/icon, ou la laisser vide (icône générique
/// de secours).
///
/// [value] / [onChanged] manipulent directement la valeur à écrire en
/// base (nom du SVG, ex: "restaurant") — le même format que lit déjà
/// `resolveEntityIcon()` partout ailleurs dans l'app. `null` = pas
/// d'icône personnalisée (fallback générique affiché).
class IconPickerField extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final IconData fallbackIcon;
  final String label;

  const IconPickerField({
    super.key,
    required this.value,
    required this.onChanged,
    this.fallbackIcon = Icons.category_outlined,
    this.label = 'Icône',
  });

  Future<void> _openPicker(BuildContext context) async {
    // Le sheet retourne :
    //  - un nom de SVG si l'admin choisit une icône
    //  - '' (chaîne vide) si l'admin choisit explicitement "Aucune"
    //  - null si le sheet est fermé sans choix (swipe/back) → on ne
    //    touche pas à la valeur actuelle
    final result = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _IconPickerSheet(
        current: value,
        fallbackIcon: fallbackIcon,
      ),
    );
    if (result == null) return;
    onChanged(result.isEmpty ? null : result);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openPicker(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider, width: 1.2),
        ),
        child: Row(
          children: [
            resolveEntityIcon(
              iconValue: value,
              fallback: fallbackIcon,
              size: 28,
              color: AppColors.iconDefault,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value == null || value!.isEmpty ? '$label (générique)' : label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.expand_more, color: AppColors.iconInactive),
          ],
        ),
      ),
    );
  }
}

class _IconPickerSheet extends StatelessWidget {
  final String? current;
  final IconData fallbackIcon;

  const _IconPickerSheet({required this.current, required this.fallbackIcon});

  @override
  Widget build(BuildContext context) {
    final isGeneric = current == null || current!.isEmpty;

    // ✅ CORRECTION : availableSvgIcons est un Set<String>, non indexable.
    // On le convertit en List une seule fois ici.
    final icons = availableSvgIcons.toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Choisir une icône',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(fallbackIcon, color: AppColors.iconInactive),
              title: const Text('Aucune (icône générique)'),
              trailing: isGeneric
                  ? const Icon(Icons.check, color: AppColors.primaryOrange)
                  : null,
              onTap: () => Navigator.pop(context, ''),
            ),
            const Divider(height: 20),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                itemCount: icons.length, // ✅
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemBuilder: (context, index) {
                  final name = icons[index]; // ✅
                  final isSelected = current == name;
                  return InkWell(
                    onTap: () => Navigator.pop(context, name),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryOrange
                              : AppColors.divider,
                          width: isSelected ? 2 : 1.2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          resolveEntityIcon(
                            iconValue: name,
                            fallback: fallbackIcon,
                            size: 26,
                            color: AppColors.iconDefault,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            name,
                            style: const TextStyle(fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
