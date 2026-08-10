import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/wallet_repository.dart';

/// §3 : achat de Qota Coin auprès de l'administration Qota.
/// L'intégration d'un vrai moyen de paiement (carte, mobile money...)
/// sera branchée ici plus tard ; pour l'instant la demande est
/// enregistrée et validée manuellement par le Super Admin (§011).
class PurchaseCoinScreen extends StatefulWidget {
  const PurchaseCoinScreen({super.key});

  @override
  State<PurchaseCoinScreen> createState() => _PurchaseCoinScreenState();
}

class _PurchaseCoinScreenState extends State<PurchaseCoinScreen> {
  final _repository = WalletRepository();
  double _selectedAmount = 50;
  bool _isSubmitting = false;

  static const _presetAmounts = [20.0, 50.0, 100.0, 250.0];

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      await _repository.requestPurchase(_selectedAmount);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demande envoyée — en attente de validation par Qota.')),
        );
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acheter des Qota Coin')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Choisissez un montant', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _presetAmounts.map((amount) {
                  final selected = amount == _selectedAmount;
                  return ChoiceChip(
                    label: Text('${amount.toStringAsFixed(0)} QC'),
                    selected: selected,
                    selectedColor: AppColors.primaryOrange.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: selected ? AppColors.primaryOrange : AppColors.textPrimary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                    ),
                    onSelected: (_) => setState(() => _selectedAmount = amount),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Demander ${_selectedAmount.toStringAsFixed(0)} Qota Coin'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Le crédit apparaîtra sur votre wallet après validation par l\'administration Qota.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
