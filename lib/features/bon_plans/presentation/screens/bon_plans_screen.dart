import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/bon_plans_repository.dart';

class BonPlansScreen extends StatefulWidget {
  const BonPlansScreen({super.key});

  @override
  State<BonPlansScreen> createState() => _BonPlansScreenState();
}

class _BonPlansScreenState extends State<BonPlansScreen> {
  final _repository = BonPlansRepository();
  late Future<List<BonPlan>> _future;

  String? _locationLabel;
  bool _isDetectingLocation = false;

  @override
  void initState() {
    super.initState();
    _future = _repository.getActiveBonPlans();
  }

  /// Détecte la position de l'utilisateur (même logique de permission
  /// que sur l'accueil) puis la traduit en un nom de ville/quartier
  /// lisible via reverse geocoding.
  Future<void> _detectLocation() async {
    setState(() => _isDetectingLocation = true);

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Localisation refusée. Autorisez-la depuis les réglages de votre appareil.')));
        }
        return;
      }

      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final label = [place.locality, place.administrativeArea]
            .where((s) => s != null && s.isNotEmpty)
            .join(', ');
        setState(() {
          _locationLabel = label.isNotEmpty ? label : 'Position détectée';
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Impossible de détecter votre position.')));
      }
    } finally {
      if (mounted) setState(() => _isDetectingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bons plans')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: _LocationBar(
              label: _locationLabel,
              isLoading: _isDetectingLocation,
              onTap: _detectLocation,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<BonPlan>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final bonPlans = snapshot.data ?? [];
                if (bonPlans.isEmpty) {
                  return const Center(
                    child: Text('Aucun bon plan pour le moment',
                        style: TextStyle(color: AppColors.textSecondary)),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bonPlans.length,
                  itemBuilder: (context, index) {
                    final plan = bonPlans[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceChip,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child:
                                Image.network(plan.imageUrl, fit: BoxFit.cover),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(plan.title,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                if (plan.description != null &&
                                    plan.description!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(plan.description!,
                                      style: const TextStyle(
                                          color: AppColors.textSecondary)),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Barre tappable affichée en haut de l'écran Bons plans : déclenche
/// la détection de la position de l'utilisateur et affiche le
/// résultat (ville/quartier) une fois disponible.
class _LocationBar extends StatelessWidget {
  final String? label;
  final bool isLoading;
  final VoidCallback onTap;

  const _LocationBar({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceChip,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on_outlined,
                color: AppColors.primaryOrange, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label ?? 'Détecter ma position',
                style: TextStyle(
                  color: label != null
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight:
                      label != null ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(Icons.my_location_rounded,
                  color: AppColors.iconDefault, size: 18),
          ],
        ),
      ),
    );
  }
}
