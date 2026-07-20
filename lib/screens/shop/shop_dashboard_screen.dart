import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/principal.dart';
import '../../models/review.dart';
import '../../models/shop_analytics.dart';
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

enum _TxnMode { earn, redeem }

class _ShopDashboardScreenState extends State<ShopDashboardScreen> {
  final _amountController = TextEditingController();
  _TxnMode _mode = _TxnMode.earn;
  bool _submitting = false;
  String? _error;
  Txn? _lastTxn;

  late Future<List<Txn>> _txnFuture;
  late Future<List<Review>> _reviewFuture;
  late Future<ShopAnalytics> _analyticsFuture;

  @override
  void initState() {
    super.initState();
    _txnFuture = context.read<ApiClient>().shopTransactions();
    _reviewFuture = _loadReviews();
    _analyticsFuture = context.read<ApiClient>().shopAnalytics();
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

  Future<void> _refreshAll() async {
    final txnFuture = context.read<ApiClient>().shopTransactions();
    final analyticsFuture = context.read<ApiClient>().shopAnalytics();
    setState(() {
      _txnFuture = txnFuture;
      _analyticsFuture = analyticsFuture;
      _reviewFuture = _loadReviews();
    });
    await Future.wait([txnFuture, analyticsFuture]);
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
      final api = context.read<ApiClient>();
      final txn = _mode == _TxnMode.redeem ? await api.createRedemption(amount) : await api.createTransaction(amount);
      setState(() {
        _lastTxn = txn;
        _amountController.clear();
      });
      _refreshAll();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _voidTransaction(Txn txn) async {
    try {
      await context.read<ApiClient>().voidTransaction(txn.id);
      if (_lastTxn?.id == txn.id) setState(() => _lastTxn = null);
      _refreshAll();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _editShopProfile() async {
    final principal = context.read<AuthProvider>().principal!;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditShopProfileSheet(principal: principal),
    );
    if (result == true && mounted) {
      await context.read<AuthProvider>().restore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final api = context.read<ApiClient>();
    final principal = context.watch<AuthProvider>().principal;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _ShopHero(name: principal?.name ?? '', category: principal?.category)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SegmentedButton<_TxnMode>(
                            segments: const [
                              ButtonSegment(
                                value: _TxnMode.earn,
                                icon: Icon(Icons.add_rounded),
                                label: Text('Earn'),
                              ),
                              ButtonSegment(
                                value: _TxnMode.redeem,
                                icon: Icon(Icons.remove_rounded),
                                label: Text('Redeem'),
                              ),
                            ],
                            selected: {_mode},
                            onSelectionChanged: (s) => setState(() => _mode = s.first),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _mode == _TxnMode.redeem ? 'Redeem cashback' : 'New transaction',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: _mode == _TxnMode.redeem ? 'Amount to redeem' : 'Purchase amount',
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
                                : Icon(_mode == _TxnMode.redeem ? Icons.remove_rounded : Icons.qr_code_2_rounded),
                            label: Text(_mode == _TxnMode.redeem ? 'Generate redeem QR' : 'Generate QR'),
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
                                    _lastTxn!.kind == TxnKind.redeem
                                        ? '-${formatCurrency(_lastTxn!.amount)}'
                                        : '${formatCurrency(_lastTxn!.amount)} · +${formatCurrency(_lastTxn!.cashbackAmount)} cashback',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Have the customer scan this in the StorePass app',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  if (_lastTxn!.status == TxnStatus.pending) ...[
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: () => _voidTransaction(_lastTxn!),
                                      child: const Text('Cancel this QR'),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Analytics', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  FutureBuilder<ShopAnalytics>(
                    future: _analyticsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done || !snapshot.hasData) {
                        return const Padding(padding: EdgeInsets.all(16), child: LoadingView());
                      }
                      final a = snapshot.data!;
                      return GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1.7,
                        children: [
                          _StatTile(value: '${a.claimedCount}/${a.generatedCount}', label: 'Claim rate (${(a.claimRate * 100).round()}%)'),
                          _StatTile(value: formatCurrency(a.totalRedeemed), label: 'Total redeemed'),
                          _StatTile(value: '${a.totalCustomers}', label: 'Customers served'),
                          _StatTile(value: '${(a.repeatCustomerRate * 100).round()}%', label: 'Repeat customers'),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Shop profile', style: theme.textTheme.titleMedium),
                      TextButton(onPressed: _editShopProfile, child: const Text('Edit')),
                    ],
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
                        return ErrorView(message: snapshot.error.toString(), onRetry: _refreshAll);
                      }
                      final txns = snapshot.data ?? [];
                      if (txns.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: EmptyState(icon: Icons.receipt_long_outlined, title: 'No transactions yet'),
                        );
                      }
                      return Column(
                        children: txns.map((t) => _TransactionRow(txn: t, onVoid: () => _voidTransaction(t))).toList(),
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
                          ...reviews.map(
                            (r) => _ReviewRow(
                              review: r,
                              onReplied: () => setState(() => _reviewFuture = _loadReviews()),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopHero extends StatelessWidget {
  final String name;
  final String? category;
  const _ShopHero({required this.name, this.category});

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0B0B10) : const Color(0xFF16161C);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 20, 24, 28),
      decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28))),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white.withValues(alpha: 0.12),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                if (category != null)
                  Text(category!, style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  const _StatTile({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: theme.textTheme.titleLarge),
            const SizedBox(height: 2),
            Text(label, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final Txn txn;
  final VoidCallback onVoid;
  const _TransactionRow({required this.txn, required this.onVoid});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRedeem = txn.kind == TxnKind.redeem;
    return Card(
      child: ListTile(
        leading: Icon(
          txn.status == TxnStatus.claimed
              ? Icons.check_circle_rounded
              : txn.status == TxnStatus.voided
                  ? Icons.block_rounded
                  : Icons.schedule_rounded,
          color: txn.status == TxnStatus.claimed ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(
          isRedeem
              ? '-${formatCurrency(txn.amount)} redeemed'
              : '${formatCurrency(txn.amount)} · +${formatCurrency(txn.cashbackAmount)}',
          style: theme.textTheme.bodyLarge?.copyWith(color: isRedeem ? theme.colorScheme.error : theme.colorScheme.primary),
        ),
        subtitle: Text(formatDate(txn.createdAt)),
        trailing: txn.status == TxnStatus.pending
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Void',
                onPressed: onVoid,
              )
            : Chip(label: Text(txn.status.name)),
      ),
    );
  }
}

class _ReviewRow extends StatefulWidget {
  final Review review;
  final VoidCallback onReplied;
  const _ReviewRow({required this.review, required this.onReplied});

  @override
  State<_ReviewRow> createState() => _ReviewRowState();
}

class _ReviewRowState extends State<_ReviewRow> {
  bool _replying = false;
  final _replyController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_replyController.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    try {
      await context.read<ApiClient>().replyToReview(widget.review.id, _replyController.text.trim());
      widget.onReplied();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = widget.review;
    return Card(
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
            if (r.shopReply != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(10),
                  border: Border(left: BorderSide(color: theme.colorScheme.primary, width: 3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your reply', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary)),
                    Text(r.shopReply!),
                  ],
                ),
              ),
            ] else if (_replying) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _replyController,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Write a reply…'),
                autofocus: true,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Post reply'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(onPressed: () => setState(() => _replying = false), child: const Text('Cancel')),
                ],
              ),
            ] else
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _replying = true),
                  icon: const Icon(Icons.reply_rounded, size: 18),
                  label: const Text('Reply'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EditShopProfileSheet extends StatefulWidget {
  final Principal principal;
  const _EditShopProfileSheet({required this.principal});

  @override
  State<_EditShopProfileSheet> createState() => _EditShopProfileSheetState();
}

class _EditShopProfileSheetState extends State<_EditShopProfileSheet> {
  late final _name = TextEditingController(text: widget.principal.name);
  late final _category = TextEditingController(text: widget.principal.category ?? '');
  late final _description = TextEditingController(text: widget.principal.description ?? '');
  late final _logoUrl = TextEditingController(text: widget.principal.logoUrl ?? '');
  late final _address = TextEditingController(text: widget.principal.address ?? '');
  late final _phone = TextEditingController(text: widget.principal.phone ?? '');
  late final _hours = TextEditingController(text: widget.principal.hours ?? '');
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _description.dispose();
    _logoUrl.dispose();
    _address.dispose();
    _phone.dispose();
    _hours.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await context.read<ApiClient>().updateMyShop(
            name: _name.text.trim(),
            category: _category.text.trim(),
            description: _description.text.trim(),
            logoUrl: _logoUrl.text.trim().isEmpty ? null : _logoUrl.text.trim(),
            address: _address.text.trim().isEmpty ? null : _address.text.trim(),
            phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
            hours: _hours.text.trim().isEmpty ? null : _hours.text.trim(),
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
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Shop profile', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Shop name')),
            const SizedBox(height: 12),
            TextField(controller: _category, decoration: const InputDecoration(labelText: 'Category')),
            const SizedBox(height: 12),
            TextField(controller: _description, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
            const SizedBox(height: 12),
            TextField(controller: _logoUrl, decoration: const InputDecoration(labelText: 'Logo URL')),
            const SizedBox(height: 12),
            TextField(controller: _address, decoration: const InputDecoration(labelText: 'Address')),
            const SizedBox(height: 12),
            TextField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone')),
            const SizedBox(height: 12),
            TextField(controller: _hours, decoration: const InputDecoration(labelText: 'Hours')),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save changes'),
            ),
          ],
        ),
      ),
    );
  }
}
