import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/transaction.dart';
import '../../services/api_client.dart';
import '../../utils/format.dart';
import '../../widgets/states.dart';
import 'shop_filter_bar.dart';

class AdminTransactionsTab extends StatefulWidget {
  const AdminTransactionsTab({super.key});

  @override
  State<AdminTransactionsTab> createState() => _AdminTransactionsTabState();
}

class _AdminTransactionsTabState extends State<AdminTransactionsTab> {
  int? _shopId;
  late Future<List<Txn>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Txn>> _load() => context.read<ApiClient>().admin.listTransactions(shopId: _shopId);

  void _onShopChanged(int? shopId) {
    setState(() {
      _shopId = shopId;
      _future = _load();
    });
  }

  Future<void> _voidTxn(Txn txn) async {
    try {
      await context.read<ApiClient>().admin.voidTransaction(txn.id);
      _onShopChanged(_shopId);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
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
            child: FutureBuilder<List<Txn>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) return const LoadingView();
                if (snapshot.hasError) {
                  return ErrorView(message: snapshot.error.toString(), onRetry: () => _onShopChanged(_shopId));
                }
                final txns = snapshot.data ?? [];
                if (txns.isEmpty) {
                  return const EmptyState(icon: Icons.receipt_long_outlined, title: 'No transactions yet');
                }
                return ListView.builder(
                  itemCount: txns.length,
                  itemBuilder: (context, i) {
                    final t = txns[i];
                    final isRedeem = t.kind == TxnKind.redeem;
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          t.status == TxnStatus.claimed
                              ? Icons.check_circle_rounded
                              : t.status == TxnStatus.voided
                                  ? Icons.block_rounded
                                  : Icons.schedule_rounded,
                          color: t.status == TxnStatus.claimed
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        title: Text('${t.shopName ?? '—'} · ${formatCurrency(t.amount)}'),
                        subtitle: Text('${t.customerName ?? 'Unclaimed'} · ${formatDate(t.createdAt)}'),
                        trailing: t.status == TxnStatus.pending
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded),
                                tooltip: 'Void',
                                onPressed: () => _voidTxn(t),
                              )
                            : Text(
                                isRedeem ? '-${formatCurrency(t.amount)}' : '+${formatCurrency(t.cashbackAmount)}',
                                style: TextStyle(
                                  color: isRedeem ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
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
