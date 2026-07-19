/// A row from `/wallets/mine` — a customer's non-zero balance at one shop.
class Wallet {
  final int shopId;
  final String shopName;
  final String shopCategory;
  final double balance;

  Wallet({
    required this.shopId,
    required this.shopName,
    required this.shopCategory,
    required this.balance,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) => Wallet(
        shopId: json['shop_id'] as int,
        shopName: json['shop_name'] as String,
        shopCategory: json['shop_category'] as String,
        balance: (json['balance'] as num).toDouble(),
      );
}
