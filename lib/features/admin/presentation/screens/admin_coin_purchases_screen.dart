import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/admin_repository.dart';

class AdminCoinPurchasesScreen extends StatefulWidget {
  const AdminCoinPurchasesScreen({super.key});

  @override
  State<AdminCoinPurchasesScreen> createState() =>
      _AdminCoinPurchasesScreenState();
}

class _AdminCoinPurchasesScreenState extends State<AdminCoinPurchasesScreen> {
  final _repository = AdminRepository();
  late Future<List<AdminCoinPurchaseRequest>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.getPendingCoinPurchaseRequests();
  }

  void _reload() =>
      setState(() => _future = _repository.getPendingCoinPurchaseRequests());

  Future<void> _approve(AdminCoinPurchaseRequest request) async {
    await _repository.approveCoinPurchase(request.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${request.amount.toStringAsFixed(0)} Qota Coin crédités à ${request.userName}.')),
      );
    }
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Achats Qota Coin')),
      body: FutureBuilder<List<AdminCoinPurchaseRequest>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final requests = snapshot.data ?? [];
          if (requests.isEmpty) {
            return const Center(
                child: Text('Aucune demande en attente',
                    style: TextStyle(color: AppColors.textSecondary)));
          }
          return ListView.separated(
            itemCount: requests.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final request = requests[index];
              return ListTile(
                title: Text(request.userName),
                subtitle: Text(
                    '${request.amount.toStringAsFixed(0)} Qota Coin demandés'),
                trailing: FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange),
                  onPressed: () => _approve(request),
                  child: const Text('Valider'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
