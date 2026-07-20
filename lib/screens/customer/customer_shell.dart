import 'package:flutter/material.dart';

import '../profile/profile_screen.dart';
import 'activity_screen.dart';
import 'my_wallets_screen.dart';
import 'scan_screen.dart';
import 'shop_directory_screen.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _index = 0;

  final _shopsKey = GlobalKey<ShopDirectoryScreenState>();
  final _walletsKey = GlobalKey<MyWalletsScreenState>();
  final _activityKey = GlobalKey<ActivityScreenState>();

  late final _tabs = [
    ShopDirectoryScreen(key: _shopsKey),
    MyWalletsScreen(key: _walletsKey),
    ActivityScreen(key: _activityKey),
    const ScanScreen(),
    const ProfileScreen(),
  ];

  void _onDestinationSelected(int i) {
    setState(() => _index = i);
    // IndexedStack keeps every tab's State alive, so initState() only runs
    // once — switching back to Shops/Wallets/Activity after a scan on
    // another tab would otherwise keep showing whatever was fetched on
    // first visit.
    if (i == 0) _shopsKey.currentState?.refresh();
    if (i == 1) _walletsKey.currentState?.refresh();
    if (i == 2) _activityKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront_rounded), label: 'Shops'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet_rounded), label: 'Wallets'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history_rounded), label: 'Activity'),
          NavigationDestination(icon: Icon(Icons.qr_code_scanner_rounded), label: 'Scan'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
