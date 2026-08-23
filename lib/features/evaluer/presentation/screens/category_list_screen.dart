import 'package:flutter/material.dart';
import '../../data/evaluer_repository.dart';
import '../widgets/simple_selection_list.dart';
import 'service_list_screen.dart';

/// §16 : catégories dynamiques (icône, ordre, actif/inactif gérés par
/// le Super Admin — jamais codées en dur).
class CategoryListScreen extends StatefulWidget {
  final String stateId;
  final String cityId;
  final String? zoneId;
  final String locationLabel;

  const CategoryListScreen({
    super.key,
    required this.stateId,
    required this.cityId,
    required this.locationLabel,
    this.zoneId,
  });

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  final _repository = EvaluerRepository();
  bool _isLoading = true;
  List<SelectionItem> _items = [];
  Map<String, dynamic> _categoriesById = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final categories = await _repository.getCategories(widget.cityId);
    setState(() {
      _categoriesById = {for (final c in categories) c.id: c};
      _items = categories
          .map((c) => SelectionItem(id: c.id, label: c.nameFr))
          .toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SimpleSelectionList(
      title: 'Catégorie',
      subtitle: 'Évaluer',
      isLoading: _isLoading,
      items: _items,
      onSelect: (item) {
        final category = _categoriesById[item.id];
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ServiceListScreen(
              category: category,
              stateId: widget.stateId,
              cityId: widget.cityId,
              zoneId: widget.zoneId,
              locationLabel: widget.locationLabel,
            ),
          ),
        );
      },
    );
  }
}
