import 'transaction.dart';

/// Response shape of `POST /transactions/claim` — distinct from `Txn` because
/// the backend returns a flatter, claim-specific payload.
class ClaimResult {
  final int transactionId;
  final int shopId;
  final String shopName;
  final TxnKind kind;
  final double amount;
  final double cashbackAmount;
  final double walletBalance;

  ClaimResult({
    required this.transactionId,
    required this.shopId,
    required this.shopName,
    this.kind = TxnKind.earn,
    required this.amount,
    required this.cashbackAmount,
    required this.walletBalance,
  });

  factory ClaimResult.fromJson(Map<String, dynamic> json) => ClaimResult(
        transactionId: json['transaction_id'] as int,
        shopId: json['shop_id'] as int,
        shopName: json['shop_name'] as String,
        kind: txnKindFromString(json['kind'] as String?),
        amount: (json['amount'] as num).toDouble(),
        cashbackAmount: (json['cashback_amount'] as num).toDouble(),
        walletBalance: (json['wallet_balance'] as num).toDouble(),
      );
}
