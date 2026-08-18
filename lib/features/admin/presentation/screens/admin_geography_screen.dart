import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/admin_repository.dart';
import 'admin_cities_screen.dart';

/// Point d'entrée "Villes & Zones" — liste des États en LECTURE SEULE
/// (la création/modification d'un État reste réservée à l'écran
/// "États", exclusivement Super Admin) : on ne fait ici que naviguer
/// jusqu'aux Villes d'un État, gérables par le Super Admin ou un
/// modérateur avec la permission 'manage_geography'.
class AdminGeographyScreen extends StatefulWidget {
  const AdminGeographyScreen({super.key});

  @override
  State<AdminGeographyScreen> createState() => _AdminGeographyScreenState();
}

class _AdminGeographyScreenState extends State<AdminGeographyScreen> {
  final _repository = AdminRepository();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.getAllStates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Villes & Zones')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final states = snapshot.data ?? [];
          if (states.isEmpty) {
            return const Center(
              child: Text('Aucun État actif pour le moment.'),
            );
          }
          return ListView.separated(
            itemCount: states.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final state = states[index];
              return ListTile(
                leading: const Icon(Icons.map_outlined,
                    color: AppColors.iconDefault),
                title: Text(state['name_fr'] as String),
                subtitle: Text(state['name_ar'] as String,
                    textDirection: TextDirection.rtl),
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: AppColors.iconInactive),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AdminCitiesScreen(
                      stateId: state['id'] as String,
                      stateName: state['name_fr'] as String,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
