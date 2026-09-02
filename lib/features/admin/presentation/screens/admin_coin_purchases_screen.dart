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
    final messageController = TextEditingController();
    final optionAController = TextEditingController();
    final optionBController = TextEditingController();
    final sent = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contacter ${request.userName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: messageController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Ex : Comment souhaitez-vous payer ?',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Les 2 réponses proposées au demandeur :',
                  style: TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              TextField(
                controller: optionAController,
                decoration: const InputDecoration(
                  labelText: 'Choix 1 (ex : Payé via D17)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: optionBController,
                decoration: const InputDecoration(
                  labelText: 'Choix 2 (ex : Pas encore payé)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
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
    if (sent != true) return;

    final message = messageController.text.trim();
    final optionA = optionAController.text.trim();
    final optionB = optionBController.text.trim();
    if (message.isEmpty || optionA.isEmpty || optionB.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Message et les 2 choix sont obligatoires.')));
      }
      return;
    }

    await _repository.sendCoinPurchaseMessage(request.id, message,
        optionA: optionA, optionB: optionB);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message envoyé.')),
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
                    '${request.amount.toStringAsFixed(0)} Qota Coin demandés'
                    '${request.userResponse != null ? '\nRéponse : ${request.userResponse}' : ''}'),
                isThreeLine: request.userResponse != null,
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
