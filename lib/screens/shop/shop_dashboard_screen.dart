import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/review.dart';
import '../../models/transaction.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../utils/format.dart';
import '../../widgets/star_rating.dart';
import '../../widgets/states.dart';

class ShopDashboardScreen extends StatefulWidget {
  const ShopDashboardScreen({super.key});

  @override
  State<ShopDashboardScreen> createState() => _ShopDashboardScreenState();
}

class _ShopDashboardScreenState extends State<ShopDashboardScreen> {
  final _amountController = TextEditingController();
  bool _submitting = false;
  String? _error;
  Txn? _lastTxn;

  late Future<List<Txn>> _txnFuture;
  late Future<List<Review>> _reviewFuture;

  @override
  void initState() {
    super.initState();
    _txnFuture = context.read<ApiClient>().shopTransactions();
    _reviewFuture = _loadReviews();
  }

  Future<List<Review>> _loadReviews() {
    final principal = context.read<AuthProvider>().principal;
    return context.read<ApiClient>().shopReviews(principal!.id);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _refreshTransactions() async {
    final future = context.read<ApiClient>().shopTransactions();
    setState(() => _txnFuture = future);
    await future;
  }

  Future<void> _createTransaction() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter an amount greater than 0');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final txn = await context.read<ApiClient>().createTransaction(amount);
      setState(() {
        _lastTxn = txn;
        _amountController.clear();
      });
      _refreshTransactions();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final api = context.read<ApiClient>();

    return Scaffold(
      appBar: AppBar(title: const Text('Shop dashboard')),
      body: RefreshIndicator(
        onRefresh: _refreshTransactions,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('New transaction', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Purchase amount',
                        prefixText: '\$ ',
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                    ],
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _submitting ? null : _createTransaction,
                      icon: _submitting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.qr_code_2_rounded),
                      label: const Text('Generate QR'),
                    ),
                    if (_lastTxn != null) ...[
                      const SizedBox(height: 20),
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: theme.colorScheme.outlineVariant),
                              ),
                              child: Image.network(
                                api.qrImageUrl(_lastTxn!.qrToken ?? ''),
                                width: 200,
                                height: 200,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${formatCurrency(_lastTxn!.amount)} · +${formatCurrency(_lastTxn!.cashbackAmount)} cashback',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Have the customer scan this in the StorePass app',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Transactions', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            FutureBuilder<List<Txn>>(
              future: _txnFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(padding: EdgeInsets.all(24), child: LoadingView());
                }
                if (snapshot.hasError) {
                  return ErrorView(message: snapshot.error.toString(), onRetry: _refreshTransactions);
                }
                final txns = snapshot.data ?? [];
                if (txns.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: EmptyState(icon: Icons.receipt_long_outlined, title: 'No transactions yet'),
                  );
                }
                return Column(
                  children: txns
                      .map((t) => Card(
                            child: ListTile(
                              leading: Icon(
                                t.status == TxnStatus.claimed ? Icons.check_circle_rounded : Icons.schedule_rounded,
                                color: t.status == TxnStatus.claimed
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                              title: Text(
                                '${formatCurrency(t.amount)} · +${formatCurrency(t.cashbackAmount)}',
                                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.primary),
                              ),
                              subtitle: Text(formatDate(t.createdAt)),
                              trailing: Chip(label: Text(t.status.name)),
                            ),
                          ))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 20),
            Text('Reviews', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            FutureBuilder<List<Review>>(
              future: _reviewFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(padding: EdgeInsets.all(24), child: LoadingView());
                }
                if (snapshot.hasError) {
                  return ErrorView(message: snapshot.error.toString());
                }
                final reviews = snapshot.data ?? [];
                if (reviews.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: EmptyState(icon: Icons.reviews_outlined, title: 'No reviews yet'),
                  );
                }
                final avg = reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
                return Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(avg.toStringAsFixed(1), style: theme.textTheme.headlineMedium),
                            StarRating(rating: avg, size: 22),
                            Text('from ${reviews.length} review${reviews.length == 1 ? '' : 's'}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...reviews.map((r) => Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(r.customerName ?? 'Customer', style: theme.textTheme.titleSmall),
                                    const Spacer(),
                                    StarRating(rating: r.rating.toDouble()),
                                  ],
                                ),
                                if (r.comment != null && r.comment!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(r.comment!),
                                ],
                              ],
                            ),
                          ),
                        )),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
