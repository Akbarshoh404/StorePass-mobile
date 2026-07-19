import 'shop.dart';
import 'transaction.dart';

/// `GET /shops/{id}` — a [Shop] plus the logged-in customer's own visit
/// history at that shop, when applicable.
class ShopDetail {
  final Shop shop;
  final List<Txn> myTransactions;

  ShopDetail({required this.shop, required this.myTransactions});

  factory ShopDetail.fromJson(Map<String, dynamic> json) => ShopDetail(
        shop: Shop.fromJson(json),
        myTransactions: (json['my_transactions'] as List<dynamic>?)
                ?.map((e) => Txn.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
