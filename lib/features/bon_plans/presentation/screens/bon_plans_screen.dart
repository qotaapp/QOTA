import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _future = _repository.getActiveBonPlans();
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
                      child: Image.network(plan.imageUrl, fit: BoxFit.cover),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(plan.title,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
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
    );
  }
}
