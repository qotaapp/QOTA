import 'package:flutter/material.dart' show IconData, Icons;
import 'package:supabase_flutter/supabase_flutter.dart';

class QotaNotification {
  final String id;
  final String type;
  final Map<String, dynamic> payload;
  final bool isRead;
  final DateTime createdAt;

  QotaNotification({
    required this.id,
    required this.type,
    required this.payload,
    required this.isRead,
    required this.createdAt,
  });

  factory QotaNotification.fromMap(Map<String, dynamic> map) =>
      QotaNotification(
        id: map['id'] as String,
        type: map['type'] as String,
        payload: Map<String, dynamic>.from(map['payload'] as Map),
        isRead: map['read_at'] != null,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  /// Texte affiché, généré à partir du type + payload (§38).
  String get message {
    switch (type) {
      case 'new_comment':
        return '${payload['author_name']} a commenté "${payload['entity_name']}"';
      case 'new_reply':
        return '${payload['author_name']} a répondu à votre commentaire';
      case 'comment_liked':
        return '${payload['liker_name']} a aimé votre commentaire';
      case 'reply_liked':
        return '${payload['liker_name']} a aimé votre réponse';
      case 'new_rating':
        return 'Nouvelle évaluation (${payload['score']}★) sur "${payload['entity_name']}"';
      case 'ownership_request_decided':
        final approved = payload['status'] == 'approved';
        return approved
            ? 'Votre demande de propriété sur "${payload['entity_name']}" a été acceptée'
            : 'Votre demande de propriété sur "${payload['entity_name']}" a été refusée';
      case 'coin_received':
        return 'Vous avez reçu ${payload['amount']} Qota Coin de ${payload['sender_name']}';
      default:
        return 'Nouvelle notification';
    }
  }

  IconData get icon {
    switch (type) {
      case 'new_comment':
      case 'new_reply':
        return Icons.chat_bubble_outline_rounded;
      case 'comment_liked':
      case 'reply_liked':
        return Icons.thumb_up_alt_rounded;
      case 'new_rating':
        return Icons.star_rounded;
      case 'ownership_request_decided':
        return Icons.verified_outlined;
      case 'coin_received':
        return Icons.monetization_on_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  /// entity_id concerné, si applicable — utilisé pour la navigation au tap.
  String? get entityId => payload['entity_id'] as String?;
}

class NotificationsRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<QotaNotification>> getNotifications() async {
    final userId = _client.auth.currentUser!.id;
    final rows = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(100);
    return (rows as List).map((r) => QotaNotification.fromMap(r)).toList();
  }

  Future<int> getUnreadCount() async {
    final userId = _client.auth.currentUser!.id;
    final rows = await _client
        .from('notifications')
        .select('id')
        .eq('user_id', userId)
        .isFilter('read_at', null);
    return (rows as List).length;
  }

  Future<void> markAsRead(String notificationId) async {
    await _client.from('notifications').update(
        {'read_at': DateTime.now().toIso8601String()}).eq('id', notificationId);
  }

  Future<void> markAllAsRead() async {
    final userId = _client.auth.currentUser!.id;
    await _client
        .from('notifications')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('user_id', userId)
        .isFilter('read_at', null);
  }
}
