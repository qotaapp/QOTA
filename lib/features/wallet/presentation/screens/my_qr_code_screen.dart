import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';

/// §3 : QR Code personnel — un autre utilisateur le scanne pour vous
/// envoyer des Qota Coin. Encode simplement l'ID utilisateur, préfixé
/// pour éviter toute confusion avec un QR d'une autre origine.
class MyQrCodeScreen extends StatelessWidget {
  const MyQrCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final qrData = 'qota:user:$userId';

    return Scaffold(
      appBar: AppBar(title: const Text('Mon QR Code')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: QrImageView(
                    data: qrData,
                    size: 220,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Montrez ce code à la personne qui souhaite vous envoyer des Qota Coin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
