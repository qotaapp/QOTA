import 'package:flutter/material.dart';
import '../../data/figures_repository.dart';
import '../../../evaluer/presentation/widgets/simple_selection_list.dart';
import 'figure_list_screen.dart';

/// §35 : point d'entrée des Figures Publiques — liste des types
/// autorisés, entièrement gérée par le Super Admin.
class FigureTypeListScreen extends StatefulWidget {
  const FigureTypeListScreen({super.key});

  @override
  State<FigureTypeListScreen> createState() => _FigureTypeListScreenState();
}

class _FigureTypeListScreenState extends State<FigureTypeListScreen> {
  final _repository = FiguresRepository();
  bool _isLoading = true;
  List<SelectionItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final types = await _repository.getFigureTypes();
    setState(() {
      _items =
          types.map((t) => SelectionItem(id: t.id, label: t.nameFr)).toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SimpleSelectionList(
      title: 'Figures publiques',
      isLoading: _isLoading,
      items: _items,
      onSelect: (item) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FigureListScreen(
                figureTypeId: item.id, figureTypeLabel: item.label),
          ),
        );
      },
    );
  }
}
