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

  Future<void> _reject(AdminCoinPurchaseRequest request) async {
    await _repository.rejectCoinPurchase(request.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Demande de ${request.userName} refusée.')),
      );
    }
    _reload();
  }

  Future<void> _openContact(AdminCoinPurchaseRequest request) async {
    final controller = TextEditingController();
    final sent = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contacter ${request.userName}'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Ex : Contactez-moi au +216 XX XXX XXX pour convenir '
                'du paiement.',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Envoyer')),
        ],
      ),
    );
    if (sent == true && controller.text.trim().isNotEmpty) {
      await _repository.sendCoinPurchaseMessage(
          request.id, controller.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message envoyé.')),
        );
      }
    }
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
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Erreur : ${snapshot.error}',
                    textAlign: TextAlign.center),
              ),
            );
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
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline,
                          color: AppColors.iconDefault),
                      tooltip: 'Contacter',
                      onPressed: () => _openContact(request),
                    ),
                    TextButton(
                      onPressed: () => _reject(request),
                      child: const Text('Refuser',
                          style: TextStyle(color: Colors.red)),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange),
                      onPressed: () => _approve(request),
                      child: const Text('Valider'),
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
