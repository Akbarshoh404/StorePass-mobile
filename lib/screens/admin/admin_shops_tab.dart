import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/shop.dart';
import '../../services/api_client.dart';
import '../../utils/format.dart';
import '../../widgets/states.dart';
import 'shop_form_sheet.dart';

class AdminShopsTab extends StatefulWidget {
  const AdminShopsTab({super.key});

  @override
  State<AdminShopsTab> createState() => _AdminShopsTabState();
}

class _AdminShopsTabState extends State<AdminShopsTab> {
  late Future<List<Shop>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Shop>> _load() => context.read<ApiClient>().admin.listShops();

  Future<void> _refresh() async {
    final future = _load();
    setState(() => _future = future);
    await future;
  }

  Future<void> _toggleActive(Shop shop) async {
    await context.read<ApiClient>().admin.updateShop(shop.id, isActive: !(shop.isActive ?? true));
    _refresh();
  }

  Future<void> _addShop() async {
    final created = await showCreateShopSheet(context, api: context.read<ApiClient>());
    if (created == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addShop,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add shop'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Shop>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const LoadingView();
            if (snapshot.hasError) return ErrorView(message: snapshot.error.toString(), onRetry: _refresh);
            final shops = snapshot.data ?? [];
            final totalTxns = shops.fold<int>(0, (s, sh) => s + (sh.totalTransactions ?? 0));
            final totalCashback = shops.fold<double>(0, (s, sh) => s + (sh.totalCashbackIssued ?? 0));
            final activeCount = shops.where((s) => s.isActive == true).length;

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                Row(
                  children: [
                    Expanded(child: _StatTile(value: '${shops.length}', label: 'Total shops')),
                    const SizedBox(width: 8),
                    Expanded(child: _StatTile(value: '$activeCount', label: 'Active')),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _StatTile(value: '$totalTxns', label: 'Transactions')),
                    const SizedBox(width: 8),
                    Expanded(child: _StatTile(value: formatCurrency(totalCashback), label: 'Cashback issued')),
                  ],
                ),
                const SizedBox(height: 16),
                if (shops.isEmpty)
                  const EmptyState(icon: Icons.storefront_outlined, title: 'No shops yet', subtitle: 'Add the first one above')
                else
                  ...shops.map((s) => _ShopRow(shop: s, onToggle: () => _toggleActive(s))),
              ],
            );
          },
        ),
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
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(value, style: theme.textTheme.titleLarge),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _ShopRow extends StatelessWidget {
  final Shop shop;
  final VoidCallback onToggle;
  const _ShopRow({required this.shop, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = shop.isActive ?? true;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(shop.name, style: theme.textTheme.titleMedium),
                      Text(shop.contact ?? '', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(value: active, onChanged: (_) => onToggle()),
                    Text(active ? 'Active' : 'Inactive', style: theme.textTheme.labelSmall),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Chip(label: Text(shop.category), visualDensity: VisualDensity.compact),
                Chip(
                  label: Text('${formatPercent(shop.cashbackRate)} rate'),
                  visualDensity: VisualDensity.compact,
                  labelStyle: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary),
                ),
                Chip(label: Text('${shop.totalTransactions ?? 0} txns'), visualDensity: VisualDensity.compact),
                Chip(
                  label: Text('${formatCurrency(shop.totalCashbackIssued ?? 0)} issued'),
                  visualDensity: VisualDensity.compact,
                ),
                Chip(
                  label: Text(shop.averageRating != null ? '${shop.averageRating} ★' : 'No rating'),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
