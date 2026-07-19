/// Mirrors `serializers.review_out()`, plus the `shop_name` the admin list adds.
class Review {
  final int id;
  final int shopId;
  final int customerId;
  final String? customerName;
  final String? shopName;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.shopId,
    required this.customerId,
    this.customerName,
    this.shopName,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id'] as int,
        shopId: json['shop_id'] as int,
        customerId: json['customer_id'] as int,
        customerName: json['customer_name'] as String?,
        shopName: json['shop_name'] as String?,
        rating: json['rating'] as int,
        comment: json['comment'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
