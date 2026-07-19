import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../models/claim_result.dart';
import '../../services/api_client.dart';
import '../../utils/format.dart';

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
      if (mounted) _showResult(result);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  void _showResult(ClaimResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.celebration_outlined, color: Theme.of(context).colorScheme.primary, size: 36),
        title: Text('Cashback earned at ${result.shopName}!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Purchase: ${formatCurrency(result.amount)}'),
            Text('Cashback: +${formatCurrency(result.cashbackAmount)}'),
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
                      child: Text(
                        'Camera unavailable (${error.errorDetails?.message ?? error.errorCode}). '
                        'Enter the code manually below.',
                        textAlign: TextAlign.center,
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
