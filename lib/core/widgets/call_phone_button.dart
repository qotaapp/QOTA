import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

/// Bouton d'appel réutilisable — utilisé sur ServiceDetailsScreen et
/// potentiellement FeedItemCard. [phoneNumber] doit être au format
/// E.164 (ex: +21612345678).
class CallPhoneButton extends StatelessWidget {
  final String phoneNumber;

  const CallPhoneButton({super.key, required this.phoneNumber});

  Future<void> _call(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de lancer l\'appel')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _call(context),
      style: OutlinedButton.styleFrom(foregroundColor: AppColors.primaryOrange),
      icon: const Icon(Icons.call_rounded),
      label: Text(phoneNumber),
    );
  }
}
