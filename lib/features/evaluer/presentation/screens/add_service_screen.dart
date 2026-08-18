import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/evaluer_models.dart';
import '../../data/evaluer_repository.dart';
import 'duplicate_found_screen.dart';

/// §19-21 : ajout d'une Service.
/// - Une image est OBLIGATOIRE.
/// - Détection de doublon avant création définitive (nom, catégorie,
///   État, ville/zone, proximité).
/// - Si la Service est nouvelle : elle est envoyée en modération —
///   le Super Admin doit l'approuver avant qu'elle soit visible,
///   évaluable ou commentable publiquement.
class AddServiceScreen extends StatefulWidget {
  final QotaCategory category;
  final String stateId;
  final String cityId;
  final String? zoneId;
  final String locationLabel;

  const AddServiceScreen({
    super.key,
    required this.category,
    required this.stateId,
    required this.cityId,
    required this.locationLabel,
    this.zoneId,
  });

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = EvaluerRepository();
  final _nameController = TextEditingController();
  final _picker = ImagePicker();

  XFile? _pickedImage;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null) {
      setState(() => _pickedImage = image);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // §19 : image obligatoire.
    if (_pickedImage == null) {
      setState(() => _errorMessage = 'Une image est obligatoire.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final name = _nameController.text.trim();

      // §19-20 : détection de doublon AVANT création définitive.
      final duplicates = await _repository.findPotentialDuplicates(
        name: name,
        cityId: widget.cityId,
        zoneId: widget.zoneId,
      );

      if (!mounted) {
        return;
      }

      if (duplicates.isNotEmpty) {
        setState(() => _isSubmitting = false);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DuplicateFoundScreen(
              potentialDuplicates: duplicates,
              onCreateAnyway: () {
                Navigator.of(context).pop(); // ferme DuplicateFoundScreen
                _createService(name);
              },
            ),
          ),
        );
        return;
      }

      // §21 : aucune Service similaire -> publication directe.
      await _createService(name);
    } catch (e) {
      setState(() {
        _errorMessage = 'Une erreur est survenue. Réessayez.';
        _isSubmitting = false;
      });
    }
  }

  Future<void> _createService(String name) async {
    if (!mounted) {
      return;
    }
    setState(() => _isSubmitting = true);

    try {
      final bytes = await _pickedImage!.readAsBytes();
      final extension = _pickedImage!.name.split('.').last;
      final imageUrl =
          await _repository.uploadImage(bytes: bytes, fileExtension: extension);

      await _repository.createService(
        name: name,
        imageUrl: imageUrl,
        categoryId: widget.category.id,
        stateId: widget.stateId,
        cityId: widget.cityId,
        zoneId: widget.zoneId,
      );

      if (!mounted) {
        return;
      }
      // Contrairement à un User Item, une Service ne s'affiche pas
      // tout de suite : elle attend l'approbation du Super Admin.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Service envoyée pour approbation. Elle sera visible dès '
                  'validation par un administrateur.'),
          duration: Duration(seconds: 4),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _errorMessage = 'Impossible de publier la service. Réessayez.';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter une service')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('${widget.category.nameFr} · ${widget.locationLabel}',
                    style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 20),

                // §19 : sélection d'image obligatoire.
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
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom de la service',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
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
                              strokeWidth: 2, color: Colors.white),
                        )
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
