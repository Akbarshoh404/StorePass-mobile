/// Shop directory entry (customer-facing `/shops`, `/shops/{id}`) and the
/// richer admin-facing shape returned by `/admin/shops`.
class Shop {
  final int id;
  final String name;
  final String category;
  final String description;
  final double cashbackRate;
  final bool? isActive;
  final double? averageRating;
  final int? reviewCount;
  final double? walletBalance;

  // Admin-only fields.
  final String? contact;
  final DateTime? createdAt;
  final int? totalTransactions;
  final double? totalCashbackIssued;

  Shop({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.cashbackRate,
    this.isActive,
    this.averageRating,
    this.reviewCount,
    this.walletBalance,
    this.contact,
    this.createdAt,
    this.totalTransactions,
    this.totalCashbackIssued,
  });

  factory Shop.fromJson(Map<String, dynamic> json) => Shop(
        id: json['id'] as int,
        name: json['name'] as String,
        category: json['category'] as String,
        description: json['description'] as String? ?? '',
        cashbackRate: (json['cashback_rate'] as num).toDouble(),
        isActive: json['is_active'] as bool?,
        averageRating: (json['average_rating'] as num?)?.toDouble(),
        reviewCount: json['review_count'] as int?,
        walletBalance: (json['wallet_balance'] as num?)?.toDouble(),
        contact: json['contact'] as String?,
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
        totalTransactions: json['total_transactions'] as int?,
        totalCashbackIssued: (json['total_cashback_issued'] as num?)?.toDouble(),
      );
}
