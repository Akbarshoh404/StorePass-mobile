import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/review.dart';
import '../../models/shop_detail.dart';
import '../../models/transaction.dart';
import '../../services/api_client.dart';
import '../../utils/format.dart';
import '../../widgets/shop_logo.dart';
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
                          ShopLogo(logoUrl: shop.logoUrl, size: 56),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Chip(label: Text(shop.category)),
                                Chip(label: Text('${formatPercent(shop.cashbackRate)} cashback')),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (shop.description.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(shop.description, style: theme.textTheme.bodyMedium),
                      ],
                      if ([shop.address, shop.phone, shop.hours].any((v) => v != null && v.isNotEmpty)) ...[
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (shop.address != null && shop.address!.isNotEmpty)
                                  _InfoRow(icon: Icons.place_outlined, text: shop.address!),
                                if (shop.phone != null && shop.phone!.isNotEmpty)
                                  _InfoRow(icon: Icons.call_outlined, text: shop.phone!),
                                if (shop.hours != null && shop.hours!.isNotEmpty)
                                  _InfoRow(icon: Icons.schedule_outlined, text: shop.hours!, isLast: true),
                              ],
                            ),
                          ),
                        ),
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
                        ...detail.myTransactions.map((t) {
                          final isRedeem = t.kind == TxnKind.redeem;
                          return Card(
                            child: ListTile(
                              leading: Icon(
                                t.status == TxnStatus.claimed ? Icons.check_circle_rounded : Icons.schedule_rounded,
                                color: t.status == TxnStatus.claimed
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                              title: Text(
                                isRedeem
                                    ? '-${formatCurrency(t.amount)} redeemed'
                                    : '${formatCurrency(t.amount)} · +${formatCurrency(t.cashbackAmount)} back',
                                style: theme.textTheme.bodyLarge
                                    ?.copyWith(color: isRedeem ? theme.colorScheme.error : theme.colorScheme.primary),
                              ),
                              subtitle: Text(formatDate(t.claimedAt ?? t.createdAt)),
                              trailing: (t.status == TxnStatus.claimed && !t.hasReview)
                                  ? TextButton(onPressed: () => _leaveReview(t), child: const Text('Rate'))
                                  : null,
                            ),
                          );
                        }),
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
                                            Text(
                                              'Shop reply',
                                              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary),
                                            ),
                                            Text(r.shopReply!),
                                          ],
                                        ),
                                      ),
                                    ],
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isLast;
  const _InfoRow({required this.icon, required this.text, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
