import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/admin_listing_repository.dart';

/// Ajout dans une section (Chaînes et programmes / Vente en ligne /
/// Autres) — accessible à tout utilisateur connecté, comme l'ajout
/// d'une Figure Publique. La publication entre en modération
/// (§022/§033) et n'apparaît qu'après approbation du Super Admin.
class AddAdminListingScreen extends StatefulWidget {
  final String typeId;
  final String typeLabel;

  const AddAdminListingScreen(
      {super.key, required this.typeId, required this.typeLabel});

  @override
  State<AddAdminListingScreen> createState() => _AddAdminListingScreenState();
}

class _AddAdminListingScreenState extends State<AddAdminListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = AdminListingRepository();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();

  XFile? _pickedImage;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null) setState(() => _pickedImage = image);
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
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
      final imageUrl =
          await _repository.uploadImage(bytes: bytes, fileExtension: extension);

      await _repository.createListing(
        name: _nameController.text.trim(),
        imageUrl: imageUrl,
        typeId: widget.typeId,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
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
      appBar: AppBar(title: Text('Ajouter — ${widget.typeLabel}')),
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
                  controller: _nameController,
                  decoration: const InputDecoration(
                      labelText: 'Nom', border: OutlineInputBorder()),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      labelText: 'Description (optionnel)',
                      border: OutlineInputBorder()),
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
