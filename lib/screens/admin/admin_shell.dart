import 'package:flutter/material.dart';

import '../profile/profile_screen.dart';
import 'admin_customers_tab.dart';
import 'admin_reviews_tab.dart';
import 'admin_shops_tab.dart';
import 'admin_transactions_tab.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  static const _titles = ['Shops', 'Customers', 'Transactions', 'Reviews', 'Profile'];

  static const _tabs = [
    AdminShopsTab(),
    AdminCustomersTab(),
    AdminTransactionsTab(),
    AdminReviewsTab(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final showsOwnAppBar = _index == 4; // ProfileScreen has its own AppBar
    return Scaffold(
      appBar: showsOwnAppBar ? null : AppBar(title: Text(_titles[_index])),
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront_rounded), label: 'Shops'),
          NavigationDestination(icon: Icon(Icons.people_outline_rounded), selectedIcon: Icon(Icons.people_rounded), label: 'Customers'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long_rounded), label: 'Txns'),
          NavigationDestination(icon: Icon(Icons.reviews_outlined), selectedIcon: Icon(Icons.reviews_rounded), label: 'Reviews'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
