import 'package:flutter/material.dart';
import '../../data/evaluer_repository.dart';
import '../widgets/simple_selection_list.dart';
import 'category_list_screen.dart';

/// §15 : zones/quartiers dynamiques (ex: Zarroug, Centre Ville, Cité
/// Ennour pour Gafsa). Si une ville n'a aucune zone définie, on passe
/// directement aux catégories.
class ZoneListScreen extends StatefulWidget {
  final String stateId;
  final String cityId;
  final String cityLabel;

  const ZoneListScreen({
    super.key,
    required this.stateId,
    required this.cityId,
    required this.cityLabel,
  });

  @override
  State<ZoneListScreen> createState() => _ZoneListScreenState();
}

class _ZoneListScreenState extends State<ZoneListScreen> {
  final _repository = EvaluerRepository();
  bool _isLoading = true;
  List<SelectionItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final zones = await _repository.getZones(widget.cityId);

    if (zones.isEmpty) {
      // Aucune zone définie pour cette ville -> passer directement aux catégories.
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => CategoryListScreen(
              stateId: widget.stateId,
              cityId: widget.cityId,
              locationLabel: widget.cityLabel,
            ),
          ),
        );
      }
      return;
    }

    setState(() {
      _items =
          zones.map((z) => SelectionItem(id: z.id, label: z.nameFr)).toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SimpleSelectionList(
      title: 'Ville / Zone',
      isLoading: _isLoading,
      items: _items,
      onSelect: (item) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CategoryListScreen(
              stateId: widget.stateId,
              cityId: widget.cityId,
              zoneId: item.id,
              locationLabel: '${widget.cityLabel} · ${item.label}',
            ),
          ),
        );
      },
    );
  }
}
