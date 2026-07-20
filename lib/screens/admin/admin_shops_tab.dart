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

  Future<void> _editShop(Shop shop) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _EditShopSheet(shop: shop, api: context.read<ApiClient>()),
      ),
    );
    if (saved == true) _refresh();
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
                  ...shops.map((s) => _ShopRow(shop: s, onToggle: () => _toggleActive(s), onEdit: () => _editShop(s))),
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
    // Distinct from plain list/content cards — a soft accent tint marks this
    // as a metric surface, matching the same treatment on web.
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.colorScheme.primary.withValues(alpha: 0.14), theme.colorScheme.surfaceContainerLow],
          stops: const [0, 0.65],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(value, style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary)),
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
  final VoidCallback onEdit;
  const _ShopRow({required this.shop, required this.onToggle, required this.onEdit});

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
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit shop',
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

/// Admin's override of any shop's full profile — the same fields a shop can
/// edit about itself (see shop_dashboard_screen.dart's edit sheet), plus the
/// admin-only cashback rate.
class _EditShopSheet extends StatefulWidget {
  final Shop shop;
  final ApiClient api;
  const _EditShopSheet({required this.shop, required this.api});

  @override
  State<_EditShopSheet> createState() => _EditShopSheetState();
}

class _EditShopSheetState extends State<_EditShopSheet> {
  late final _name = TextEditingController(text: widget.shop.name);
  late final _category = TextEditingController(text: widget.shop.category);
  late final _contact = TextEditingController(text: widget.shop.contact ?? '');
  late final _description = TextEditingController(text: widget.shop.description);
  late final _logoUrl = TextEditingController(text: widget.shop.logoUrl ?? '');
  late final _address = TextEditingController(text: widget.shop.address ?? '');
  late final _phone = TextEditingController(text: widget.shop.phone ?? '');
  late final _hours = TextEditingController(text: widget.shop.hours ?? '');
  late final _rate = TextEditingController(text: (widget.shop.cashbackRate * 100).toStringAsFixed(0));
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _contact.dispose();
    _description.dispose();
    _logoUrl.dispose();
    _address.dispose();
    _phone.dispose();
    _hours.dispose();
    _rate.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final rate = double.tryParse(_rate.text.trim());
    if (rate == null || rate < 0 || rate > 100) {
      setState(() => _error = 'Cashback rate must be a number between 0 and 100');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.api.admin.updateShop(
        widget.shop.id,
        name: _name.text.trim(),
        category: _category.text.trim(),
        contact: _contact.text.trim(),
        description: _description.text.trim(),
        logoUrl: _logoUrl.text.trim().isEmpty ? null : _logoUrl.text.trim(),
        address: _address.text.trim().isEmpty ? null : _address.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        hours: _hours.text.trim().isEmpty ? null : _hours.text.trim(),
        cashbackRate: rate / 100,
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Edit ${widget.shop.name}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Shop name')),
            const SizedBox(height: 12),
            TextField(controller: _category, decoration: const InputDecoration(labelText: 'Category')),
            const SizedBox(height: 12),
            TextField(controller: _contact, decoration: const InputDecoration(labelText: 'Login contact')),
            const SizedBox(height: 12),
            TextField(
              controller: _rate,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Cashback rate (%)'),
            ),
            const SizedBox(height: 12),
            TextField(controller: _description, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
            const SizedBox(height: 12),
            TextField(controller: _logoUrl, decoration: const InputDecoration(labelText: 'Logo URL')),
            const SizedBox(height: 12),
            TextField(controller: _address, decoration: const InputDecoration(labelText: 'Address')),
            const SizedBox(height: 12),
            TextField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone')),
            const SizedBox(height: 12),
            TextField(controller: _hours, decoration: const InputDecoration(labelText: 'Hours')),
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
      ),
    );
  }
}
