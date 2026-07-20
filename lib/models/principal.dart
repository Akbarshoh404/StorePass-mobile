enum Role { admin, customer, shop }

Role roleFromString(String value) {
  switch (value) {
    case 'admin':
      return Role.admin;
    case 'shop':
      return Role.shop;
    default:
      return Role.customer;
  }
}

/// The logged-in identity — an admin, a customer, or a shop — normalized into
/// one shape, mirroring `serializers.principal_out()` on the backend.
class Principal {
  final int id;
  final String name;
  final String contact;
  final Role role;
  final String? category;
  final String? description;
  final String? logoUrl;
  final String? address;
  final String? phone;
  final String? hours;
  final double? cashbackRate;
  final bool? isActive;
  final bool hasPassword;

  Principal({
    required this.id,
    required this.name,
    required this.contact,
    required this.role,
    this.category,
    this.description,
    this.logoUrl,
    this.address,
    this.phone,
    this.hours,
    this.cashbackRate,
    this.isActive,
    this.hasPassword = true,
  });

  factory Principal.fromJson(Map<String, dynamic> json) => Principal(
        id: json['id'] as int,
        name: json['name'] as String,
        contact: json['contact'] as String,
        role: roleFromString(json['role'] as String),
        category: json['category'] as String?,
        description: json['description'] as String?,
        logoUrl: json['logo_url'] as String?,
        address: json['address'] as String?,
        phone: json['phone'] as String?,
        hours: json['hours'] as String?,
        cashbackRate: (json['cashback_rate'] as num?)?.toDouble(),
        isActive: json['is_active'] as bool?,
        hasPassword: json['has_password'] as bool? ?? true,
      );
}
