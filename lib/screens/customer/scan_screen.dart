import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../models/claim_result.dart';
import '../../models/transaction.dart';
import '../../services/api_client.dart';
import '../../utils/format.dart';
import 'review_dialog.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController _controller = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
  final _manualController = TextEditingController();
  bool _claiming = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _manualController.dispose();
    super.dispose();
  }

  Future<void> _claim(String token) async {
    if (_claiming || token.trim().isEmpty) return;
    setState(() {
      _claiming = true;
      _error = null;
    });
    try {
      final result = await context.read<ApiClient>().claimTransaction(token.trim());
      HapticFeedback.mediumImpact();
      if (mounted) await _showResult(result);
    } on ApiException catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      // Anything other than ApiException (an unexpected response shape, a
      // parsing slip, etc.) must still surface *something* — silently
      // falling through here is exactly the "nothing happens, no modal"
      // failure mode this guards against.
      HapticFeedback.heavyImpact();
      if (mounted) setState(() => _error = 'Could not claim this code — try again.');
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  Future<void> _showResult(ClaimResult result) async {
    final isRedeem = result.kind == TxnKind.redeem;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          isRedeem ? Icons.redeem_rounded : Icons.celebration_outlined,
          color: isRedeem ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
          size: 36,
        ),
        title: Text(isRedeem ? 'Redeemed at ${result.shopName}' : 'Cashback earned at ${result.shopName}!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isRedeem)
              Text('Redeemed: -${formatCurrency(result.amount)}')
            else ...[
              Text('Purchase: ${formatCurrency(result.amount)}'),
              Text('Cashback: +${formatCurrency(result.cashbackAmount)}'),
            ],
            const SizedBox(height: 8),
            Text(
              'New wallet balance: ${formatCurrency(result.walletBalance)}',
              style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary),
            ),
          ],
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Done')),
        ],
      ),
    );

    // Redeeming isn't a "visit" — only prompt for a rating after earning
    // cashback, same as the web scan flow.
    if (!isRedeem && mounted) {
      final txn = Txn(
        id: result.transactionId,
        shopId: result.shopId,
        shopName: result.shopName,
        kind: TxnKind.earn,
        amount: result.amount,
        cashbackAmount: result.cashbackAmount,
        status: TxnStatus.claimed,
        createdAt: DateTime.now(),
        hasReview: false,
      );
      await showReviewDialog(context, api: context.read<ApiClient>(), transaction: txn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan to claim'),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, state, child) => Icon(
                state.torchState == TorchState.on ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              ),
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: (capture) {
                    final code = capture.barcodes.firstOrNull?.rawValue;
                    if (code != null) _claim(code);
                  },
                  errorBuilder: (context, error) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            error.errorCode == MobileScannerErrorCode.permissionDenied
                                ? 'Camera access was denied. Enable it in Settings to scan, '
                                    'or enter the code manually below.'
                                : 'Camera unavailable (${error.errorDetails?.message ?? error.errorCode}). '
                                    'Enter the code manually below.',
                            textAlign: TextAlign.center,
                          ),
                          if (error.errorCode == MobileScannerErrorCode.permissionDenied) ...[
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: openAppSettings,
                              child: const Text('Open settings'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                IgnorePointer(
                  child: Center(
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 1.5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
                if (_claiming)
                  const ColoredBox(
                    color: Colors.black45,
                    child: Center(child: CircularProgressIndicator(color: Colors.white)),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _manualController,
                        decoration: const InputDecoration(
                          labelText: 'Enter code manually',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _claiming ? null : () => _claim(_manualController.text),
                      child: const Text('Claim'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
