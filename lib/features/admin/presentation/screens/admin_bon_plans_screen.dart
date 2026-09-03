import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/admin_repository.dart';

class AdminBonPlansScreen extends StatefulWidget {
  const AdminBonPlansScreen({super.key});

  @override
  State<AdminBonPlansScreen> createState() => _AdminBonPlansScreenState();
}

class _AdminBonPlansScreenState extends State<AdminBonPlansScreen> {
  final _repository = AdminRepository();
  late Future<List<AdminBonPlan>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.getBonPlans();
  }

  void _reload() => setState(() => _future = _repository.getBonPlans());

  Future<void> _toggleActive(AdminBonPlan plan, bool value) async {
    await _repository.toggleBonPlanActive(plan.id, value);
    _reload();
  }

  Future<void> _delete(AdminBonPlan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce bon plan ?'),
        content: Text(plan.title),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirmed == true) {
      await _repository.deleteBonPlan(plan.id);
      _reload();
    }
  }

  Future<void> _openAdd() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const _AddBonPlanScreen()),
    );
    if (created == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bons plans')),
      body: FutureBuilder<List<AdminBonPlan>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final plans = snapshot.data ?? [];
          if (plans.isEmpty) {
            return const Center(
                child: Text('Aucun bon plan pour le moment',
                    style: TextStyle(color: AppColors.textSecondary)));
          }
          return ListView.separated(
            itemCount: plans.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final plan = plans[index];
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(plan.imageUrl,
                      width: 48, height: 48, fit: BoxFit.cover),
                ),
                title: Text(plan.title),
                subtitle: plan.description != null
                    ? Text(plan.description!,
                        maxLines: 1, overflow: TextOverflow.ellipsis)
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: plan.active,
                      onChanged: (v) => _toggleActive(plan, v),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _delete(plan),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryOrange,
        onPressed: _openAdd,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
    );
  }
}

class _AddBonPlanScreen extends StatefulWidget {
  const _AddBonPlanScreen();

  @override
  State<_AddBonPlanScreen> createState() => _AddBonPlanScreenState();
}

class _AddBonPlanScreenState extends State<_AddBonPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = AdminRepository();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _linkController = TextEditingController();
  final _picker = ImagePicker();

  XFile? _pickedImage;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<Map<String, dynamic>> _states = [];
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _zones = [];
  String? _selectedStateId;
  String? _selectedCityId;
  String? _selectedZoneId;

  @override
  void initState() {
    super.initState();
    _loadStates();
  }

  Future<void> _loadStates() async {
    final states = await _repository.getAllStates();
    if (mounted) setState(() => _states = states);
  }

  Future<void> _onStateChanged(String? stateId) async {
    setState(() {
      _selectedStateId = stateId;
      _selectedCityId = null;
      _selectedZoneId = null;
      _cities = [];
      _zones = [];
    });
    if (stateId == null) return;
    final cities = await _repository.getCitiesForState(stateId);
    if (mounted) setState(() => _cities = cities);
  }

  Future<void> _onCityChanged(String? cityId) async {
    setState(() {
      _selectedCityId = cityId;
      _selectedZoneId = null;
      _zones = [];
    });
    if (cityId == null) return;
    final zones = await _repository.getZonesForCity(cityId);
    if (mounted) setState(() => _zones = zones);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null) setState(() => _pickedImage = image);
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedImage == null) {
      setState(() => _errorMessage = 'Une image est obligatoire.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final bytes = await _pickedImage!.readAsBytes();
      final extension = _pickedImage!.name.split('.').last;
      final imageUrl = await _repository.uploadBonPlanImage(
          bytes: bytes, fileExtension: extension);

      await _repository.createBonPlan(
        title: _titleController.text.trim(),
        imageUrl: imageUrl,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        linkUrl: _linkController.text.trim().isEmpty
            ? null
            : _linkController.text.trim(),
        cityId: _selectedCityId,
        zoneId: _selectedZoneId,
      );

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _errorMessage = 'Impossible de publier. Réessayez.';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un bon plan')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceChip,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _pickedImage == null
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_a_photo_outlined,
                                    size: 32, color: AppColors.iconInactive),
                                SizedBox(height: 8),
                                Text('Ajouter une image (obligatoire)',
                                    style: TextStyle(
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                          )
                        : Image.file(File(_pickedImage!.path),
                            fit: BoxFit.cover, width: double.infinity),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                      labelText: 'Titre', border: OutlineInputBorder()),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Titre requis' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      labelText: 'Description (optionnel)',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _linkController,
                  decoration: const InputDecoration(
                      labelText: 'Lien (optionnel)',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                      'Localisation (optionnel — laisser vide = national)',
                      style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedStateId,
                  decoration: const InputDecoration(
                      labelText: 'État', border: OutlineInputBorder()),
                  items: _states
                      .map((s) => DropdownMenuItem(
                            value: s['id'] as String,
                            child: Text(s['name_fr'] as String),
                          ))
                      .toList(),
                  onChanged: _onStateChanged,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCityId,
                  decoration: const InputDecoration(
                      labelText: 'Ville', border: OutlineInputBorder()),
                  items: _cities
                      .map((c) => DropdownMenuItem(
                            value: c['id'] as String,
                            child: Text(c['name_fr'] as String),
                          ))
                      .toList(),
                  onChanged: _selectedStateId == null ? null : _onCityChanged,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedZoneId,
                  decoration: const InputDecoration(
                      labelText: 'Zone (optionnel)',
                      border: OutlineInputBorder()),
                  items: _zones
                      .map((z) => DropdownMenuItem(
                            value: z['id'] as String,
                            child: Text(z['name_fr'] as String),
                          ))
                      .toList(),
                  onChanged: _selectedCityId == null
                      ? null
                      : (v) => setState(() => _selectedZoneId = v),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(_errorMessage!,
                      style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 28),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Publier'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
