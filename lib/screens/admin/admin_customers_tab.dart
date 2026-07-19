import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/customer.dart';
import '../../services/api_client.dart';
import '../../utils/format.dart';
import '../../widgets/states.dart';

class AdminCustomersTab extends StatefulWidget {
  const AdminCustomersTab({super.key});

  @override
  State<AdminCustomersTab> createState() => _AdminCustomersTabState();
}

class _AdminCustomersTabState extends State<AdminCustomersTab> {
  late Future<List<AdminCustomer>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<ApiClient>().admin.listCustomers();
  }

  Future<void> _refresh() async {
    final future = context.read<ApiClient>().admin.listCustomers();
    setState(() => _future = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<AdminCustomer>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const LoadingView();
          if (snapshot.hasError) return ErrorView(message: snapshot.error.toString(), onRetry: _refresh);
          final customers = snapshot.data ?? [];
          if (customers.isEmpty) {
            return const EmptyState(icon: Icons.people_outline_rounded, title: 'No customers have registered yet');
          }
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: customers.length,
            itemBuilder: (context, i) {
              final c = customers[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text(c.name.isNotEmpty ? c.name[0].toUpperCase() : '?')),
                  title: Text(c.name),
                  subtitle: Text('${c.contact} · joined ${formatDate(c.createdAt)}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(formatCurrency(c.totalBalance), style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('${c.walletCount} wallet${c.walletCount == 1 ? '' : 's'}', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
