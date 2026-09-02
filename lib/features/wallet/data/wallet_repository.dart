import 'package:supabase_flutter/supabase_flutter.dart';
import '../../notifications/data/notifications_repository.dart';

class WalletTransaction {
  final String id;
  final String type; // purchase | transfer_in | transfer_out | spend | refund
  final double amount;
  final String? reference;
  final DateTime createdAt;

  WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.createdAt,
    this.reference,
  });

  factory WalletTransaction.fromMap(Map<String, dynamic> map) =>
      WalletTransaction(
        id: map['id'] as String,
        type: map['type'] as String,
        amount: (map['amount'] as num).toDouble(),
        reference: map['reference'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

/// État courant d'une demande d'achat, propre au demandeur — pour
/// savoir si un message du Super Admin attend encore une réponse.
class CoinPurchaseRequestState {
  final String id;
  final String? pendingMessage;
  final String? pendingOptionA;
  final String? pendingOptionB;
  final String? userResponse;

  CoinPurchaseRequestState({
    required this.id,
    this.pendingMessage,
    this.pendingOptionA,
    this.pendingOptionB,
    this.userResponse,
  });

  bool get needsResponse => pendingMessage != null && userResponse == null;

  factory CoinPurchaseRequestState.fromMap(Map<String, dynamic> map) {
    final pending = map['pending_message'] as Map<String, dynamic>?;
    return CoinPurchaseRequestState(
      id: map['id'] as String,
      pendingMessage: pending?['message'] as String?,
      pendingOptionA: pending?['option_a'] as String?,
      pendingOptionB: pending?['option_b'] as String?,
      userResponse: map['user_response'] as String?,
    );
  }
}

class WalletRepository {
  final SupabaseClient _client = Supabase.instance.client;

  String get currentUserId => _client.auth.currentUser!.id;

  Future<double> getBalance() async {
    final row = await _client
        .from('wallets')
        .select('balance')
        .eq('user_id', currentUserId)
        .single();
    return (row['balance'] as num).toDouble();
  }

  Future<List<WalletTransaction>> getTransactions() async {
    final rows = await _client
        .from('wallet_transactions')
        .select()
        .eq('wallet_user_id', currentUserId)
        .order('created_at', ascending: false)
        .limit(50);
    return (rows as List).map((r) => WalletTransaction.fromMap(r)).toList();
  }

  /// §3 : "acheter des Qota Coin auprès de l'administration Qota" —
  /// crée une demande, validée ensuite par le Super Admin (011).
  Future<void> requestPurchase(double amount) async {
    await _client.rpc('request_coin_purchase', params: {'p_amount': amount});
  }

  /// §3 : transfert à un autre utilisateur via QR Code. Le QR encode
  /// simplement l'ID utilisateur du destinataire.
  Future<Map<String, dynamic>> transferCoin({
    required String recipientId,
    required double amount,
  }) async {
    final result = await _client.rpc('transfer_qota_coin', params: {
      'p_recipient_id': recipientId,
      'p_amount': amount,
    });
    return result as Map<String, dynamic>;
  }

  /// Notifications liées au Wallet (achats/messages Qota Coin,
  /// transferts reçus) — affichées dans l'Historique du Wallet
  /// plutôt que dans l'écran Notifications général.
  Future<List<QotaNotification>> getWalletNotifications() async {
    final rows = await _client
        .from('notifications')
        .select()
        .eq('user_id', currentUserId)
        .inFilter('type', const [
          'coin_purchase_message',
          'coin_purchase_approved',
          'coin_purchase_rejected',
          'coin_received',
        ])
        .order('created_at', ascending: false)
        .limit(50);
    return (rows as List).map((r) => QotaNotification.fromMap(r)).toList();
  }

  /// État de mes propres demandes d'achat — pour savoir si un
  /// message envoyé par le Super Admin attend encore une réponse.
  Future<Map<String, CoinPurchaseRequestState>>
      getMyCoinPurchaseRequestsState() async {
    final rows = await _client
        .from('coin_purchase_requests')
        .select('id, pending_message, user_response')
        .eq('user_id', currentUserId);
    final states =
        (rows as List).map((r) => CoinPurchaseRequestState.fromMap(r)).toList();
    return {for (final s in states) s.id: s};
  }

  /// Répond à l'un des 2 choix envoyés par le Super Admin sur une
  /// demande — visible ensuite dans Achats Qota Coin.
  Future<void> respondToCoinPurchaseMessage({
    required String requestId,
    required String chosenOption,
  }) async {
    await _client.rpc('respond_coin_purchase_message', params: {
      'p_request_id': requestId,
      'p_chosen': chosenOption,
    });
  }
}
