import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/review.dart';
import '../../services/api_client.dart';
import '../../utils/format.dart';
import '../../widgets/star_rating.dart';
import '../../widgets/states.dart';
import 'shop_filter_bar.dart';

class AdminReviewsTab extends StatefulWidget {
  const AdminReviewsTab({super.key});

  @override
  State<AdminReviewsTab> createState() => _AdminReviewsTabState();
}

class _AdminReviewsTabState extends State<AdminReviewsTab> {
  int? _shopId;
  late Future<List<Review>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Review>> _load() => context.read<ApiClient>().admin.listReviews(shopId: _shopId);

  void _reload() => setState(() => _future = _load());

  void _onShopChanged(int? shopId) {
    setState(() {
      _shopId = shopId;
      _future = _load();
    });
  }

  Future<void> _delete(Review review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove review?'),
        content: Text('This removes ${review.customerName ?? "this customer"}\'s review permanently.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<ApiClient>().admin.deleteReview(review.id);
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ShopFilterBar(selectedShopId: _shopId, onChanged: _onShopChanged),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<Review>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) return const LoadingView();
                if (snapshot.hasError) {
                  return ErrorView(message: snapshot.error.toString(), onRetry: () => _onShopChanged(_shopId));
                }
                final reviews = snapshot.data ?? [];
                if (reviews.isEmpty) {
                  return const EmptyState(icon: Icons.reviews_outlined, title: 'No reviews yet');
                }
                return ListView.builder(
                  itemCount: reviews.length,
                  itemBuilder: (context, i) {
                    final r = reviews[i];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${r.customerName ?? 'Customer'} → ${r.shopName ?? ''}',
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline_rounded, color: Theme.of(context).colorScheme.error),
                                  tooltip: 'Remove review',
                                  onPressed: () => _delete(r),
                                ),
                              ],
                            ),
                            StarRating(rating: r.rating.toDouble()),
                            if (r.comment != null && r.comment!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(r.comment!),
                            ],
                            const SizedBox(height: 4),
                            Text(formatDate(r.createdAt), style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
