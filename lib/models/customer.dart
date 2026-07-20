/// A row from the admin-only `/admin/customers` list.
class AdminCustomer {
  final int id;
  final String name;
  final String contact;
  final DateTime createdAt;
  final double totalBalance;
  final int walletCount;
  final bool isActive;

  AdminCustomer({
    required this.id,
    required this.name,
    required this.contact,
    required this.createdAt,
    required this.totalBalance,
    required this.walletCount,
    this.isActive = true,
  });

  factory AdminCustomer.fromJson(Map<String, dynamic> json) => AdminCustomer(
        id: json['id'] as int,
        name: json['name'] as String,
        contact: json['contact'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        totalBalance: (json['total_balance'] as num).toDouble(),
        walletCount: json['wallet_count'] as int,
        isActive: json['is_active'] as bool? ?? true,
      );
}
