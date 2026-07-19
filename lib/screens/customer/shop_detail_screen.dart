import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/review.dart';
import '../../models/shop_detail.dart';
import '../../models/transaction.dart';
import '../../services/api_client.dart';
import '../../utils/format.dart';
import '../../widgets/star_rating.dart';
import '../../widgets/states.dart';
import 'review_dialog.dart';

class ShopDetailScreen extends StatefulWidget {
  final int shopId;
  const ShopDetailScreen({super.key, required this.shopId});

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  late Future<(ShopDetail, List<Review>)> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<(ShopDetail, List<Review>)> _load() async {
    final api = context.read<ApiClient>();
    final detail = await api.shopDetail(widget.shopId);
    final reviews = await api.shopReviews(widget.shopId);
    return (detail, reviews);
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() => _future = future);
    await future;
  }

  Future<void> _leaveReview(Txn txn) async {
    final api = context.read<ApiClient>();
    final result = await showReviewDialog(context, api: api, transaction: txn);
    if (result == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<(ShopDetail, List<Review>)>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingView();
          }
          if (snapshot.hasError) {
            return ErrorView(message: snapshot.error.toString(), onRetry: _refresh);
          }
          final (detail, reviews) = snapshot.data!;
          final shop = detail.shop;
          final theme = Theme.of(context);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(title: Text(shop.name), pinned: true),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Row(
                        children: [
                          Chip(label: Text(shop.category)),
                          const SizedBox(width: 8),
                          Chip(label: Text('${formatPercent(shop.cashbackRate)} cashback')),
                        ],
                      ),
                      if (shop.description.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(shop.description, style: theme.textTheme.bodyMedium),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (shop.averageRating != null) ...[
                            StarRating(rating: shop.averageRating!, size: 20),
                            const SizedBox(width: 8),
                            Text('${shop.averageRating} · ${shop.reviewCount} reviews'),
                          ] else
                            const Text('No reviews yet'),
                        ],
                      ),
                      if (shop.walletBalance != null) ...[
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(Icons.account_balance_wallet_outlined, color: theme.colorScheme.onSurfaceVariant),
                                const SizedBox(width: 12),
                                Text('Your wallet', style: theme.textTheme.bodyMedium),
                                const Spacer(),
                                Text(
                                  formatCurrency(shop.walletBalance!),
                                  style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      if (detail.myTransactions.isNotEmpty) ...[
                        Text('Your visits', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        ...detail.myTransactions.map((t) => Card(
                              child: ListTile(
                                leading: Icon(
                                  t.status == TxnStatus.claimed ? Icons.check_circle_rounded : Icons.schedule_rounded,
                                  color: t.status == TxnStatus.claimed
                                      ? theme.colorScheme.onSurface
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                                title: Text(
                                  '${formatCurrency(t.amount)} · +${formatCurrency(t.cashbackAmount)} back',
                                  style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.primary),
                                ),
                                subtitle: Text(formatDate(t.claimedAt ?? t.createdAt)),
                                trailing: (t.status == TxnStatus.claimed && !t.hasReview)
                                    ? TextButton(onPressed: () => _leaveReview(t), child: const Text('Rate'))
                                    : null,
                              ),
                            )),
                        const SizedBox(height: 24),
                      ],
                      Text('Reviews', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      if (reviews.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text('No reviews yet.', style: theme.textTheme.bodyMedium),
                        )
                      else
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
                                    const SizedBox(height: 4),
                                    Text(formatDate(r.createdAt), style: theme.textTheme.bodySmall),
                                  ],
                                ),
                              ),
                            )),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
