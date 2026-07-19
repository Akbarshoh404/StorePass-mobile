enum TxnStatus { pending, claimed }

TxnStatus txnStatusFromString(String value) => value == 'claimed' ? TxnStatus.claimed : TxnStatus.pending;

/// Mirrors `serializers.transaction_out()`, plus the optional fields some
/// endpoints add on top (`qr_token`/`qr_image_url` on create, `customer_name`
/// on the admin list).
class Txn {
  final int id;
  final int shopId;
  final String? shopName;
  final double amount;
  final double cashbackAmount;
  final TxnStatus status;
  final DateTime createdAt;
  final DateTime? claimedAt;
  final bool hasReview;
  final String? qrToken;
  final String? customerName;

  Txn({
    required this.id,
    required this.shopId,
    this.shopName,
    required this.amount,
    required this.cashbackAmount,
    required this.status,
    required this.createdAt,
    this.claimedAt,
    required this.hasReview,
    this.qrToken,
    this.customerName,
  });

  factory Txn.fromJson(Map<String, dynamic> json) => Txn(
        id: json['id'] as int,
        shopId: json['shop_id'] as int,
        shopName: json['shop_name'] as String?,
        amount: (json['amount'] as num).toDouble(),
        cashbackAmount: (json['cashback_amount'] as num).toDouble(),
        status: txnStatusFromString(json['status'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        claimedAt: json['claimed_at'] != null ? DateTime.parse(json['claimed_at'] as String) : null,
        hasReview: json['has_review'] as bool? ?? false,
        qrToken: json['qr_token'] as String?,
        customerName: json['customer_name'] as String?,
      );
}
