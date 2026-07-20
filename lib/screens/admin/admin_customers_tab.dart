import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/customer.dart';
import '../../models/shop.dart';
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
  List<Shop> _shops = [];

  @override
  void initState() {
    super.initState();
    _future = context.read<ApiClient>().admin.listCustomers();
    context.read<ApiClient>().admin.listShops().then((shops) {
      if (mounted) setState(() => _shops = shops);
    });
  }

  Future<void> _refresh() async {
    final future = context.read<ApiClient>().admin.listCustomers();
    setState(() => _future = future);
    await future;
  }

  Future<void> _toggleActive(AdminCustomer c) async {
    final api = context.read<ApiClient>().admin;
    try {
      if (c.isActive) {
        await api.suspendCustomer(c.id);
      } else {
        await api.reactivateCustomer(c.id);
      }
      _refresh();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _adjustWallet(AdminCustomer c) async {
    if (_shops.isEmpty) return;
    final adjusted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AdjustWalletSheet(customer: c, shops: _shops),
    );
    if (adjusted == true) _refresh();
  }

  Future<void> _editCustomer(AdminCustomer c) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _EditCustomerSheet(customer: c),
      ),
    );
    if (saved == true) _refresh();
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      ListTile(
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
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
                        child: Row(
                          children: [
                            Chip(
                              label: Text(c.isActive ? 'Active' : 'Suspended'),
                              backgroundColor: c.isActive
                                  ? null
                                  : Theme.of(context).colorScheme.errorContainer,
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => _editCustomer(c),
                              child: const Text('Edit'),
                            ),
                            TextButton(
                              onPressed: () => _adjustWallet(c),
                              child: const Text('Adjust balance'),
                            ),
                            TextButton(
                              onPressed: () => _toggleActive(c),
                              style: TextButton.styleFrom(
                                foregroundColor: c.isActive ? Theme.of(context).colorScheme.error : null,
                              ),
                              child: Text(c.isActive ? 'Suspend' : 'Reactivate'),
                            ),
                          ],
                        ),
                      ),
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

class _AdjustWalletSheet extends StatefulWidget {
  final AdminCustomer customer;
  final List<Shop> shops;
  const _AdjustWalletSheet({required this.customer, required this.shops});

  @override
  State<_AdjustWalletSheet> createState() => _AdjustWalletSheetState();
}

class _AdjustWalletSheetState extends State<_AdjustWalletSheet> {
  late int _shopId = widget.shops.first.id;
  final _deltaController = TextEditingController();
  final _noteController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _deltaController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final delta = double.tryParse(_deltaController.text.trim());
    if (delta == null || delta == 0) {
      setState(() => _error = 'Enter a non-zero amount (negative to deduct)');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await context.read<ApiClient>().admin.adjustWallet(
            customerId: widget.customer.id,
            shopId: _shopId,
            delta: delta,
            note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("Adjust ${widget.customer.name}'s balance", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: _shopId,
            decoration: const InputDecoration(labelText: 'Shop'),
            items: widget.shops.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
            onChanged: (v) => setState(() => _shopId = v ?? _shopId),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _deltaController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            decoration: const InputDecoration(labelText: 'Amount (negative to deduct)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Apply adjustment'),
          ),
        ],
      ),
    );
  }
}

class _EditCustomerSheet extends StatefulWidget {
  final AdminCustomer customer;
  const _EditCustomerSheet({required this.customer});

  @override
  State<_EditCustomerSheet> createState() => _EditCustomerSheetState();
}

class _EditCustomerSheetState extends State<_EditCustomerSheet> {
  late final _name = TextEditingController(text: widget.customer.name);
  late final _contact = TextEditingController(text: widget.customer.contact);
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await context.read<ApiClient>().admin.updateCustomer(
            widget.customer.id,
            name: _name.text.trim(),
            contact: _contact.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Edit ${widget.customer.name}', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
          const SizedBox(height: 12),
          TextField(controller: _contact, decoration: const InputDecoration(labelText: 'Contact (email/phone)')),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save changes'),
          ),
        ],
      ),
    );
  }
}
