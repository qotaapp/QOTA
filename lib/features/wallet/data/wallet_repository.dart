import 'package:supabase_flutter/supabase_flutter.dart';

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
}
