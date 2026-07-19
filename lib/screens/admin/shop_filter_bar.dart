import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/shop.dart';
import '../../services/api_client.dart';

/// "All shops" / per-shop dropdown used by the admin Transactions and Reviews
/// tabs to filter their lists, mirroring the frontend's `<select>` toolbar.
class ShopFilterBar extends StatefulWidget {
  final int? selectedShopId;
  final ValueChanged<int?> onChanged;
  const ShopFilterBar({super.key, required this.selectedShopId, required this.onChanged});

  @override
  State<ShopFilterBar> createState() => _ShopFilterBarState();
}

class _ShopFilterBarState extends State<ShopFilterBar> {
  late Future<List<Shop>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<ApiClient>().admin.listShops();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Shop>>(
      future: _future,
      builder: (context, snapshot) {
        final shops = snapshot.data ?? [];
        return DropdownButtonFormField<int?>(
          initialValue: widget.selectedShopId,
          decoration: const InputDecoration(
            labelText: 'Shop',
            isDense: true,
          ),
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('All shops')),
            ...shops.map((s) => DropdownMenuItem<int?>(value: s.id, child: Text(s.name))),
          ],
          onChanged: widget.onChanged,
        );
      },
    );
  }
}
