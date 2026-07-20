import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/transaction.dart';
import '../../services/api_client.dart';
import '../../utils/format.dart';
import '../../widgets/states.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => ActivityScreenState();
}

class ActivityScreenState extends State<ActivityScreen> {
  late Future<List<Txn>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<ApiClient>().myTransactions();
  }

  Future<void> refresh() async {
    final future = context.read<ApiClient>().myTransactions();
    setState(() => _future = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity')),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: FutureBuilder<List<Txn>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return const LoadingView();
            if (snapshot.hasError) return ErrorView(message: snapshot.error.toString(), onRetry: refresh);
            final txns = snapshot.data ?? [];
            if (txns.isEmpty) {
              return const EmptyState(
                icon: Icons.history_rounded,
                title: 'No activity yet',
                subtitle: "Scan a QR code at any shop to see it here.",
              );
            }
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: txns.length,
              itemBuilder: (context, i) {
                final t = txns[i];
                final isRedeem = t.kind == TxnKind.redeem;
                return Card(
                  child: ListTile(
                    leading: Icon(
                      isRedeem ? Icons.redeem_rounded : Icons.storefront_rounded,
                      color: isRedeem ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    title: Text('${t.shopName ?? 'Shop'} · ${isRedeem ? 'Redeemed' : 'Purchase'}'),
                    subtitle: Text(formatDate(t.claimedAt ?? t.createdAt)),
                    trailing: Text(
                      isRedeem ? '-${formatCurrency(t.amount)}' : '+${formatCurrency(t.cashbackAmount)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isRedeem ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
