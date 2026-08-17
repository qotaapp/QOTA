import 'package:flutter/material.dart';
import '../../data/evaluer_repository.dart';
import '../widgets/simple_selection_list.dart';
import 'city_list_screen.dart';

/// §13-14 : point d'entrée du parcours Évaluer.
/// Affiche la liste des États — initialement les 24 gouvernorats de
/// Tunisie, mais entièrement gérés depuis la base (jamais codés en dur),
/// pour permettre au Super Admin d'ajouter/modifier/désactiver un État.
class EvaluerScreen extends StatefulWidget {
  const EvaluerScreen({super.key});

  @override
  State<EvaluerScreen> createState() => _EvaluerScreenState();
}

class _EvaluerScreenState extends State<EvaluerScreen> {
  final _repository = EvaluerRepository();
  bool _isLoading = true;
  List<SelectionItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final states = await _repository.getStates();
    setState(() {
      _items =
          states.map((s) => SelectionItem(id: s.id, label: s.nameFr)).toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SimpleSelectionList(
      title: 'État',
      isLoading: _isLoading,
      items: _items,
      onSelect: (item) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                CityListScreen(stateId: item.id, stateLabel: item.label),
          ),
        );
      },
    );
  }
}
