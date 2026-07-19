import 'package:flutter/material.dart';

import '../../models/transaction.dart';
import '../../services/api_client.dart';
import '../../widgets/star_rating.dart';

/// Shown after a customer picks an eligible (claimed, unreviewed) transaction
/// to leave a star rating + optional comment for that visit.
Future<bool?> showReviewDialog(BuildContext context, {required ApiClient api, required Txn transaction}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => _ReviewDialog(api: api, transaction: transaction),
  );
}

class _ReviewDialog extends StatefulWidget {
  final ApiClient api;
  final Txn transaction;
  const _ReviewDialog({required this.api, required this.transaction});

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.api.createReview(
        transactionId: widget.transaction.id,
        rating: _rating,
        comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Rate ${widget.transaction.shopName ?? 'your visit'}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StarRatingInput(value: _rating, onChanged: (v) => setState(() => _rating = v)),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Add a comment (optional)',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Submit'),
        ),
      ],
    );
  }
}
