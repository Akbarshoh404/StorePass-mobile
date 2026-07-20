class DailyRevenue {
  final String date;
  final double revenue;
  final double cashback;

  DailyRevenue({required this.date, required this.revenue, required this.cashback});

  factory DailyRevenue.fromJson(Map<String, dynamic> json) => DailyRevenue(
        date: json['date'] as String,
        revenue: (json['revenue'] as num).toDouble(),
        cashback: (json['cashback'] as num).toDouble(),
      );
}

/// `GET /transactions/shop-mine/analytics`.
class ShopAnalytics {
  final List<DailyRevenue> dailyRevenue;
  final int generatedCount;
  final int claimedCount;
  final double claimRate;
  final double totalRedeemed;
  final int totalCustomers;
  final int repeatCustomers;
  final double repeatCustomerRate;

  ShopAnalytics({
    required this.dailyRevenue,
    required this.generatedCount,
    required this.claimedCount,
    required this.claimRate,
    required this.totalRedeemed,
    required this.totalCustomers,
    required this.repeatCustomers,
    required this.repeatCustomerRate,
  });

  factory ShopAnalytics.fromJson(Map<String, dynamic> json) => ShopAnalytics(
        dailyRevenue: (json['daily_revenue'] as List<dynamic>)
            .map((e) => DailyRevenue.fromJson(e as Map<String, dynamic>))
            .toList(),
        generatedCount: json['generated_count'] as int,
        claimedCount: json['claimed_count'] as int,
        claimRate: (json['claim_rate'] as num).toDouble(),
        totalRedeemed: (json['total_redeemed'] as num).toDouble(),
        totalCustomers: json['total_customers'] as int,
        repeatCustomers: json['repeat_customers'] as int,
        repeatCustomerRate: (json['repeat_customer_rate'] as num).toDouble(),
      );
}
