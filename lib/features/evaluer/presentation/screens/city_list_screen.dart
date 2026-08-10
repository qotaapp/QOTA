import 'package:flutter/material.dart';
import '../../data/evaluer_repository.dart';
import '../widgets/simple_selection_list.dart';
import 'zone_list_screen.dart';

class CityListScreen extends StatefulWidget {
  final String stateId;
  final String stateLabel;

  const CityListScreen({super.key, required this.stateId, required this.stateLabel});

  @override
  State<CityListScreen> createState() => _CityListScreenState();
}

class _CityListScreenState extends State<CityListScreen> {
  final _repository = EvaluerRepository();
  bool _isLoading = true;
  List<SelectionItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cities = await _repository.getCities(widget.stateId);
    setState(() {
      _items = cities.map((c) => SelectionItem(id: c.id, label: c.nameFr)).toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SimpleSelectionList(
      title: widget.stateLabel,
      isLoading: _isLoading,
      items: _items,
      onSelect: (item) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ZoneListScreen(
              stateId: widget.stateId,
              cityId: item.id,
              cityLabel: item.label,
            ),
          ),
        );
      },
    );
  }
}
