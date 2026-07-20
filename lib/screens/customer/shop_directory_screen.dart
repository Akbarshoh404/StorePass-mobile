import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/shop.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../utils/format.dart';
import '../../widgets/shop_logo.dart';
import '../../widgets/star_rating.dart';
import '../../widgets/states.dart';
import 'shop_detail_screen.dart';

class ShopDirectoryScreen extends StatefulWidget {
  const ShopDirectoryScreen({super.key});

  @override
  State<ShopDirectoryScreen> createState() => ShopDirectoryScreenState();
}

class ShopDirectoryScreenState extends State<ShopDirectoryScreen> {
  late Future<List<Shop>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Shop>> _load() => context.read<ApiClient>().listShops();

  Future<void> refresh() async {
    final future = _load();
    setState(() => _future = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final principal = context.watch<AuthProvider>().principal;
    final bg = Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1C1C1E) : const Color(0xFF16161C);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: refresh,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 24),
                decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi, ${principal?.name.split(' ').first ?? 'there'}',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Find a shop and start earning',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 14),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search shops or categories',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                        prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withValues(alpha: 0.7)),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.1),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                    ),
                  ],
                ),
              ),
            ),
            FutureBuilder<List<Shop>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const SliverFillRemaining(child: LoadingView());
                }
                if (snapshot.hasError) {
                  return SliverFillRemaining(child: ErrorView(message: snapshot.error.toString(), onRetry: refresh));
                }
                var shops = snapshot.data ?? [];
                if (_query.isNotEmpty) {
                  shops = shops
                      .where((s) => s.name.toLowerCase().contains(_query) || s.category.toLowerCase().contains(_query))
                      .toList();
                }
                if (shops.isEmpty) {
                  return const SliverFillRemaining(child: EmptyState(icon: Icons.storefront_outlined, title: 'No shops found'));
                }
                return SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList.separated(
                    itemCount: shops.length,
                    separatorBuilder: (context, i) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _ShopCard(shop: shops[i]),
                  ),
                );
              },
            ),
          ],
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
                  ShopLogo(logoUrl: shop.logoUrl),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(shop.name, style: theme.textTheme.titleMedium),
                        Text(shop.category, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Text(
                    '${formatPercent(shop.cashbackRate)} back',
                    style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary),
                  ),
                ],
              ),
              if (shop.description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  shop.description,
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
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
