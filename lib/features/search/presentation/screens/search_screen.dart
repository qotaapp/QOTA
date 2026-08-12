import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/search_repository.dart';
import '../../../evaluer/presentation/screens/service_details_screen.dart';

/// §12 : recherche de services, lieux, catégories, contenus pertinents.
/// Debounce de 400ms pour ne pas spammer le serveur à chaque frappe.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _repository = SearchRepository();
  final _controller = TextEditingController();
  Timer? _debounce;

  List<SearchResultCategory> _categories = [];
  List<SearchResultEntity> _entities = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() {
        _categories = [];
        _entities = [];
        _hasSearched = false;
      });
      return;
    }
    _debounce = Timer(
        const Duration(milliseconds: 400), () => _runSearch(value.trim()));
  }

  Future<void> _runSearch(String query) async {
    setState(() => _isLoading = true);
    final (categories, entities) = await _repository.search(query);
    if (!mounted) return;
    setState(() {
      _categories = categories;
      _entities = entities;
      _isLoading = false;
      _hasSearched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _onChanged,
          decoration: const InputDecoration(
            hintText: 'Rechercher un service, un lieu, une catégorie...',
            border: InputBorder.none,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : !_hasSearched
                ? const Center(
                    child: Text('Commencez à taper pour rechercher',
                        style: TextStyle(color: AppColors.textSecondary)),
                  )
                : (_categories.isEmpty && _entities.isEmpty)
                    ? const Center(
                        child: Text('Aucun résultat',
                            style: TextStyle(color: AppColors.textSecondary)),
                      )
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 24),
                        children: [
                          if (_categories.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Text('Catégories',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w700)),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _categories
                                    .map((c) => Chip(
                                          label: Text(c.nameFr),
                                          backgroundColor:
                                              AppColors.surfaceChip,
                                        ))
                                    .toList(),
                              ),
                            ),
                          ],
                          if (_entities.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                              child: Text('Résultats',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w700)),
                            ),
                            ..._entities.map((entity) => ListTile(
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: entity.imageUrl,
                                      width: 52,
                                      height: 52,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  title: Text(entity.name),
                                  subtitle: Text(
                                    entity.locationLabel.isNotEmpty
                                        ? entity.locationLabel
                                        : _kindLabel(entity.kind),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star_rounded,
                                          size: 16,
                                          color: AppColors.starFilled),
                                      const SizedBox(width: 2),
                                      Text(entity.averageScore
                                          .toStringAsFixed(1)),
                                    ],
                                  ),
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (_) => ServiceDetailsScreen(
                                            entityId: entity.id)),
                                  ),
                                )),
                          ],
                        ],
                      ),
      ),
    );
  }

  String _kindLabel(String kind) {
    switch (kind) {
      case 'user_item':
        return 'User Item';
      case 'public_figure':
        return 'Figure publique';
      default:
        return 'Service';
    }
  }
}
