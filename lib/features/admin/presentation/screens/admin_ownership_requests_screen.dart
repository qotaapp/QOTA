import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/admin_repository.dart';

class AdminOwnershipRequestsScreen extends StatefulWidget {
  const AdminOwnershipRequestsScreen({super.key});

  @override
  State<AdminOwnershipRequestsScreen> createState() =>
      _AdminOwnershipRequestsScreenState();
}

class _AdminOwnershipRequestsScreenState
    extends State<AdminOwnershipRequestsScreen> {
  final _repository = AdminRepository();
  late Future<List<AdminOwnershipRequest>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.getPendingOwnershipRequests();
  }

  void _reload() =>
      setState(() => _future = _repository.getPendingOwnershipRequests());

  Future<void> _decide(AdminOwnershipRequest request, bool approve) async {
    await _repository.decideOwnershipRequest(request.id, approve);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(approve ? 'Propriété transférée.' : 'Demande refusée.')),
      );
    }
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Demandes de propriété')),
      body: FutureBuilder<List<AdminOwnershipRequest>>(
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
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.entityName,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('Demandeur : ${request.requesterName}',
                        style: const TextStyle(color: AppColors.textSecondary)),
                    if (request.message != null &&
                        request.message!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(request.message!),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _decide(request, false),
                            child: const Text('Refuser'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primaryOrange),
                            onPressed: () => _decide(request, true),
                            child: const Text('Approuver'),
                          ),
                        ),
                      ],
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
