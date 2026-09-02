import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../notifications/data/notifications_repository.dart';
import '../../data/wallet_repository.dart';
import 'purchase_coin_screen.dart';
import 'my_qr_code_screen.dart';
import 'scan_transfer_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _repository = WalletRepository();
  late Future<_WalletData> _futureData;
  final Set<String> _respondingIds = {};

  @override
  void initState() {
    super.initState();
    _futureData = _load();
  }

  Future<_WalletData> _load() async {
    final balance = await _repository.getBalance();
    final transactions = await _repository.getTransactions();
    final notifications = await _repository.getWalletNotifications();
    final requestStates = await _repository.getMyCoinPurchaseRequestsState();
    return _WalletData(
      balance: balance,
      transactions: transactions,
      notifications: notifications,
      requestStates: requestStates,
    );
  }

  void _reload() => setState(() => _futureData = _load());

  Future<void> _respond(QotaNotification notification, String chosen) async {
    final requestId = notification.payload['request_id'] as String;
    setState(() => _respondingIds.add(notification.id));
    try {
      await _repository.respondToCoinPurchaseMessage(
          requestId: requestId, chosenOption: chosen);
      if (mounted) _reload();
    } finally {
      if (mounted) setState(() => _respondingIds.remove(notification.id));
    }
  }

  String _label(WalletTransaction tx) {
    switch (tx.type) {
      case 'purchase':
        return 'Achat de Qota Coin';
      case 'transfer_in':
        return 'Reçu par transfert';
      case 'transfer_out':
        return 'Envoyé par transfert';
      case 'spend':
        return tx.reference == 'name_change' ? 'Changement de nom' : 'Dépense';
      case 'refund':
        return 'Remboursement';
      default:
        return tx.type;
    }
  }

  /// Un message du Super Admin nécessite une réponse à 2 choix
  /// SEULEMENT s'il correspond au message actuellement en attente
  /// sur la demande (les messages précédents, déjà remplacés ou déjà
  /// répondus, s'affichent en simple historique).
  bool _needsResponse(
      QotaNotification n, Map<String, CoinPurchaseRequestState> states) {
    if (n.type != 'coin_purchase_message') return false;
    final requestId = n.payload['request_id'] as String?;
    final state = requestId != null ? states[requestId] : null;
    return state != null &&
        state.needsResponse &&
        state.pendingMessage == n.payload['message'] &&
        state.pendingOptionA == n.payload['option_a'] &&
        state.pendingOptionB == n.payload['option_b'];
  }

  Widget _buildNotificationEntry(
      QotaNotification n, Map<String, CoinPurchaseRequestState> states) {
    if (_needsResponse(n, states)) {
      final optionA = n.payload['option_a'] as String;
      final optionB = n.payload['option_b'] as String;
      final busy = _respondingIds.contains(n.id);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceChip,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(n.icon, color: AppColors.primaryOrange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(n.message)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: busy ? null : () => _respond(n, optionA),
                      child: Text(optionA),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange),
                      onPressed: busy ? null : () => _respond(n, optionB),
                      child: Text(optionB),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return ListTile(
      leading: Icon(n.icon, color: AppColors.iconDefault),
      title: Text(n.message),
      subtitle:
          Text('${n.createdAt.day}/${n.createdAt.month}/${n.createdAt.year}'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mon Wallet')),
      body: SafeArea(
        child: FutureBuilder<_WalletData>(
          future: _futureData,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data!;
            final entries = [
              ...data.transactions.map(_HistoryEntry.tx),
              ...data.notifications.map(_HistoryEntry.notif),
            ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView(
                children: [
                  Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Solde',
                            style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 6),
                        Text(
                          '${data.balance.toStringAsFixed(0)} Qota Coin',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.add_circle_outline_rounded,
                            label: 'Acheter',
                            onTap: () => Navigator.of(context)
                                .push(MaterialPageRoute(
                                    builder: (_) => const PurchaseCoinScreen()))
                                .then((_) => _reload()),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.qr_code_rounded,
                            label: 'Mon QR',
                            onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const MyQrCodeScreen())),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.qr_code_scanner_rounded,
                            label: 'Envoyer',
                            onTap: () => Navigator.of(context)
                                .push(MaterialPageRoute(
                                    builder: (_) => const ScanTransferScreen()))
                                .then((_) => _reload()),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Historique',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (entries.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text('Aucune activité pour le moment',
                            style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    )
                  else
                    ...entries.map((entry) {
                      if (entry.notification != null) {
                        return _buildNotificationEntry(
                            entry.notification!, data.requestStates);
                      }
                      final tx = entry.transaction!;
                      final positive = tx.amount >= 0;
                      return ListTile(
                        leading: Icon(
                          positive
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                          color:
                              positive ? Colors.green : AppColors.textSecondary,
                        ),
                        title: Text(_label(tx)),
                        subtitle: Text(
                            '${tx.createdAt.day}/${tx.createdAt.month}/${tx.createdAt.year}'),
                        trailing: Text(
                          '${positive ? '+' : ''}${tx.amount.toStringAsFixed(0)} QC',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color:
                                positive ? Colors.green : AppColors.textPrimary,
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceChip,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.iconDefault),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _WalletData {
  final double balance;
  final List<WalletTransaction> transactions;
  final List<QotaNotification> notifications;
  final Map<String, CoinPurchaseRequestState> requestStates;

  _WalletData({
    required this.balance,
    required this.transactions,
    required this.notifications,
    required this.requestStates,
  });
}

/// Entrée unifiée de l'Historique — soit une transaction wallet,
/// soit une notification liée au Wallet (message, validation, refus,
/// réception), triées ensemble par date.
class _HistoryEntry {
  final DateTime createdAt;
  final WalletTransaction? transaction;
  final QotaNotification? notification;

  _HistoryEntry.tx(WalletTransaction tx)
      : transaction = tx,
        notification = null,
        createdAt = tx.createdAt;

  _HistoryEntry.notif(QotaNotification n)
      : transaction = null,
        notification = n,
        createdAt = n.createdAt;
}
