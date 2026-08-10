import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/wallet_repository.dart';

/// §3 : scanner le QR d'un autre utilisateur, saisir un montant,
/// confirmer — le transfert est atomique côté serveur (011).
class ScanTransferScreen extends StatefulWidget {
  const ScanTransferScreen({super.key});

  @override
  State<ScanTransferScreen> createState() => _ScanTransferScreenState();
}

class _ScanTransferScreenState extends State<ScanTransferScreen> {
  bool _hasScanned = false;

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || !code.startsWith('qota:user:')) return;

    final recipientId = code.replaceFirst('qota:user:', '');
    setState(() => _hasScanned = true);

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _TransferAmountScreen(recipientId: recipientId)),
    ).then((_) => setState(() => _hasScanned = false));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scanner un QR Code')),
      body: MobileScanner(onDetect: _onDetect),
    );
  }
}

class _TransferAmountScreen extends StatefulWidget {
  final String recipientId;
  const _TransferAmountScreen({required this.recipientId});

  @override
  State<_TransferAmountScreen> createState() => _TransferAmountScreenState();
}

class _TransferAmountScreenState extends State<_TransferAmountScreen> {
  final _repository = WalletRepository();
  final _amountController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _confirmTransfer() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Montant invalide');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final result = await _repository.transferCoin(recipientId: widget.recipientId, amount: amount);

      if (!mounted) return;

      if (result['status'] == 'insufficient_funds') {
        setState(() {
          _errorMessage = 'Solde insuffisant (${result['balance']} Qota Coin disponibles).';
          _isSubmitting = false;
        });
        return;
      }

      Navigator.of(context).pop();
      Navigator.of(context).pop(); // ferme aussi l'écran scanner
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${amount.toStringAsFixed(0)} Qota Coin envoyés avec succès.')),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Le transfert a échoué. Réessayez.';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transférer des Qota Coin')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Montant (Qota Coin)',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 20),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isSubmitting ? null : _confirmTransfer,
                child: _isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Confirmer le transfert'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
