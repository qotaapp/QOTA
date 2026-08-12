import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/notifications_repository.dart';
import '../../../evaluer/presentation/screens/service_details_screen.dart';
import '../../../comments/presentation/screens/comments_screen.dart';
import '../../../wallet/presentation/screens/wallet_screen.dart';

/// §38 : liste des notifications utilisateur, avec navigation
/// contextuelle vers l'entité, le commentaire ou le wallet concerné.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _repository = NotificationsRepository();
  late Future<List<QotaNotification>> _futureNotifications;

  @override
  void initState() {
    super.initState();
    _futureNotifications = _repository.getNotifications();
  }

  void _reload() {
    setState(() => _futureNotifications = _repository.getNotifications());
  }

  Future<void> _handleTap(QotaNotification notification) async {
    if (!notification.isRead) {
      await _repository.markAsRead(notification.id);
    }

    switch (notification.type) {
      case 'new_comment':
      case 'new_rating':
        if (notification.entityId != null && mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  ServiceDetailsScreen(entityId: notification.entityId!),
            ),
          );
        }
        break;
      case 'new_reply':
      case 'comment_liked':
        if (notification.entityId != null && mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CommentsScreen(
                  entityId: notification.entityId!, entityKind: 'service'),
            ),
          );
        }
        break;
      case 'ownership_request_decided':
        if (notification.entityId != null && mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  ServiceDetailsScreen(entityId: notification.entityId!),
            ),
          );
        }
        break;
      case 'coin_received':
        if (mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const WalletScreen()),
          );
        }
        break;
    }

    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              await _repository.markAllAsRead();
              _reload();
            },
            child: const Text('Tout marquer lu'),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<QotaNotification>>(
          future: _futureNotifications,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final notifications = snapshot.data ?? [];
            if (notifications.isEmpty) {
              return const Center(
                child: Text('Aucune notification pour le moment',
                    style: TextStyle(color: AppColors.textSecondary)),
              );
            }
            return ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return ListTile(
                  leading: Icon(
                    notification.icon,
                    color: notification.isRead
                        ? AppColors.iconInactive
                        : AppColors.primaryOrange,
                  ),
                  title: Text(
                    notification.message,
                    style: TextStyle(
                      fontWeight: notification.isRead
                          ? FontWeight.normal
                          : FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(_formatRelativeTime(notification.createdAt)),
                  onTap: () => _handleTap(notification),
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _formatRelativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    return 'Il y a ${diff.inDays} j';
  }
}
