import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../evaluer/presentation/widgets/simple_selection_list.dart';
import '../../data/bon_plans_repository.dart';

class BonPlansScreen extends StatefulWidget {
  const BonPlansScreen({super.key});

  @override
  State<BonPlansScreen> createState() => _BonPlansScreenState();
}

class _BonPlansScreenState extends State<BonPlansScreen> {
  final _repository = BonPlansRepository();
  late Future<List<BonPlan>> _future;

  DetectedCity? _detectedCity;
  bool _isDetecting = false;
  String? _detectionError;

  @override
  void initState() {
    super.initState();
    _future = _repository.getActiveBonPlans();
  }

  Future<void> _detectLocation() async {
    setState(() {
      _isDetecting = true;
      _detectionError = null;
    });

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _isDetecting = false;
          _detectionError = 'Localisation refusée — choisissez votre ville.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final city =
          await _repository.detectCity(position.latitude, position.longitude);

      if (!mounted) return;
      if (city == null) {
        setState(() {
          _isDetecting = false;
          _detectionError = 'Ville non reconnue — choisissez-la manuellement.';
        });
        return;
      }

      setState(() {
        _detectedCity = city;
        _isDetecting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDetecting = false;
        _detectionError = 'Détection impossible — choisissez votre ville.';
      });
    }
  }

  Future<void> _pickCityManually() async {
    final cities = await _repository.getAllActiveCities();
    if (!mounted) return;

    final selected = await Navigator.of(context).push<DetectedCity>(
      MaterialPageRoute(
        builder: (_) => _CityPickerScreen(cities: cities),
      ),
    );
    if (selected != null) {
      setState(() {
        _detectedCity = selected;
        _detectionError = null;
      });
    }
  }

  Widget _buildLocationBar() {
    final label = _isDetecting
        ? 'Détection en cours…'
        : _detectedCity != null
            ? _detectedCity!.nameFr
            : 'Détecter ma localisation';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: InkWell(
        onTap: _isDetecting
            ? null
            : (_detectedCity == null ? _detectLocation : _pickCityManually),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceChip,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _isDetecting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(
                      _detectedCity != null
                          ? Icons.location_on_rounded
                          : Icons.my_location_rounded,
                      color: AppColors.primaryOrange,
                      size: 20,
                    ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              if (_detectedCity != null)
                TextButton(
                  onPressed: _pickCityManually,
                  child: const Text('Changer'),
                ),
              if (_detectedCity == null && !_isDetecting)
                TextButton(
                  onPressed: _pickCityManually,
                  child: const Text('Choisir'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bons plans')),
      body: FutureBuilder<List<BonPlan>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final allPlans = snapshot.data ?? [];
          // Un Bon Plan sans ville/zone est national (toujours
          // visible). Sinon, ne s'affiche que si sa ville ou sa zone
          // correspond à la localisation choisie/détectée.
          final bonPlans = _detectedCity == null
              ? allPlans
              : allPlans
                  .where((p) => p.isNational || p.cityId == _detectedCity!.id)
                  .toList();

          return Column(
            children: [
              _buildLocationBar(),
              if (_detectionError != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(_detectionError!,
                        style:
                            const TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                ),
              Expanded(
                child: bonPlans.isEmpty
                    ? const Center(
                        child: Text('Aucun bon plan pour le moment',
                            style: TextStyle(color: AppColors.textSecondary)),
                      )
                    : ListView.builder(
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
                                  child: Image.network(plan.imageUrl,
                                      fit: BoxFit.cover),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                                color:
                                                    AppColors.textSecondary)),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CityPickerScreen extends StatelessWidget {
  final List<DetectedCity> cities;
  const _CityPickerScreen({required this.cities});

  @override
  Widget build(BuildContext context) {
    return SimpleSelectionList(
      title: 'Ville',
      subtitle: 'Bons plans',
      isLoading: false,
      items:
          cities.map((c) => SelectionItem(id: c.id, label: c.nameFr)).toList(),
      onSelect: (item) => Navigator.of(context).pop(
        DetectedCity(id: item.id, nameFr: item.label),
      ),
    );
  }
}
