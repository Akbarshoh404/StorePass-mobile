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
  State<MyWalletsScreen> createState() => MyWalletsScreenState();
}

class MyWalletsScreenState extends State<MyWalletsScreen> {
  late Future<List<Wallet>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<ApiClient>().myWallets();
  }

  Future<void> refresh() async {
    final future = context.read<ApiClient>().myWallets();
    setState(() => _future = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1C1C1E) : const Color(0xFF16161C);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: refresh,
        child: FutureBuilder<List<Wallet>>(
          future: _future,
          builder: (context, snapshot) {
            final wallets = snapshot.data ?? [];
            final total = wallets.fold<double>(0, (sum, w) => sum + w.balance);

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 28),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My wallets',
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Total across shops',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatCurrency(total),
                          style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
                if (snapshot.connectionState != ConnectionState.done)
                  const SliverFillRemaining(child: LoadingView())
                else if (snapshot.hasError)
                  SliverFillRemaining(child: ErrorView(message: snapshot.error.toString(), onRetry: refresh))
                else if (wallets.isEmpty)
                  const SliverFillRemaining(
                    child: EmptyState(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'No cashback yet',
                      subtitle: 'Scan a shop\'s QR code after a purchase to start earning.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList.separated(
                      itemCount: wallets.length,
                      separatorBuilder: (context, i) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final w = wallets[i];
                        return Card(
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
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
