import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/shop.dart';
import '../../services/api_client.dart';
import '../../utils/format.dart';
import '../../widgets/star_rating.dart';
import '../../widgets/states.dart';
import 'shop_detail_screen.dart';

class ShopDirectoryScreen extends StatefulWidget {
  const ShopDirectoryScreen({super.key});

  @override
  State<ShopDirectoryScreen> createState() => _ShopDirectoryScreenState();
}

class _ShopDirectoryScreenState extends State<ShopDirectoryScreen> {
  late Future<List<Shop>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Shop>> _load() => context.read<ApiClient>().listShops();

  Future<void> _refresh() async {
    final future = _load();
    setState(() => _future = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shops'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search shops or categories',
                prefixIcon: Icon(Icons.search_rounded),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Shop>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const LoadingView();
            if (snapshot.hasError) {
              return ErrorView(message: snapshot.error.toString(), onRetry: _refresh);
            }
            var shops = snapshot.data ?? [];
            if (_query.isNotEmpty) {
              shops = shops
                  .where((s) => s.name.toLowerCase().contains(_query) || s.category.toLowerCase().contains(_query))
                  .toList();
            }
            if (shops.isEmpty) {
              return const EmptyState(icon: Icons.storefront_outlined, title: 'No shops found');
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: shops.length,
              separatorBuilder: (context, i) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _ShopCard(shop: shops[i]),
            );
          },
        ),
      ),
    );
  }
}

class _ShopCard extends StatelessWidget {
  final Shop shop;
  const _ShopCard({required this.shop});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ShopDetailScreen(shopId: shop.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(shop.name, style: theme.textTheme.titleMedium),
                  ),
                  Text(
                    '${formatPercent(shop.cashbackRate)} back',
                    style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(shop.category, style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (shop.averageRating != null) ...[
                    StarRating(rating: shop.averageRating!),
                    const SizedBox(width: 6),
                    Text('${shop.averageRating} (${shop.reviewCount})', style: theme.textTheme.bodySmall),
                  ] else
                    Text('No reviews yet', style: theme.textTheme.bodySmall),
                  const Spacer(),
                  if (shop.walletBalance != null && shop.walletBalance! > 0)
                    Text(
                      formatCurrency(shop.walletBalance!),
                      style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
