import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/wallet.dart';
import '../../services/api_client.dart';
import '../../utils/format.dart';
import '../../widgets/states.dart';
import 'shop_detail_screen.dart';

class MyWalletsScreen extends StatefulWidget {
  const MyWalletsScreen({super.key});

  @override
  State<MyWalletsScreen> createState() => _MyWalletsScreenState();
}

class _MyWalletsScreenState extends State<MyWalletsScreen> {
  late Future<List<Wallet>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<ApiClient>().myWallets();
  }

  Future<void> _refresh() async {
    final future = context.read<ApiClient>().myWallets();
    setState(() => _future = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My wallets')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Wallet>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const LoadingView();
            if (snapshot.hasError) return ErrorView(message: snapshot.error.toString(), onRetry: _refresh);
            final wallets = snapshot.data ?? [];
            if (wallets.isEmpty) {
              return const EmptyState(
                icon: Icons.account_balance_wallet_outlined,
                title: 'No cashback yet',
                subtitle: 'Scan a shop\'s QR code after a purchase to start earning.',
              );
            }
            final total = wallets.fold<double>(0, (sum, w) => sum + w.balance);
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text('Total across shops', style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 4),
                        Text(
                          formatCurrency(total),
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(color: Theme.of(context).colorScheme.primary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...wallets.map((w) => Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.storefront_outlined)),
                        title: Text(w.shopName),
                        subtitle: Text(w.shopCategory),
                        trailing: Text(
                          formatCurrency(w.balance),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ShopDetailScreen(shopId: w.shopId)),
                        ),
                      ),
                    )),
              ],
            );
          },
        ),
      ),
    );
  }
}
