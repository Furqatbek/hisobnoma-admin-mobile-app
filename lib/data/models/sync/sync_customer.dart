class SyncCustomer {
  final int id;
  final String code;
  final String name;
  final String? phone;
  final String? email;
  final int? priceListId;
  final double creditLimit;
  final double currentBalance;
  final bool active;
  final DateTime updatedAt;

  const SyncCustomer({
    required this.id,
    required this.code,
    required this.name,
    this.phone,
    this.email,
    this.priceListId,
    required this.creditLimit,
    required this.currentBalance,
    required this.active,
    required this.updatedAt,
  });

  factory SyncCustomer.fromJson(Map<String, dynamic> json) {
    return SyncCustomer(
      id: json['id'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      priceListId: json['priceListId'] as int?,
      creditLimit: (json['creditLimit'] as num?)?.toDouble() ?? 0,
      currentBalance: (json['currentBalance'] as num?)?.toDouble() ?? 0,
      active: json['active'] as bool? ?? true,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toDbRow() => {
        'id': id,
        'code': code,
        'name': name,
        'phone': phone,
        'email': email,
        'price_list_id': priceListId,
        'credit_limit': creditLimit,
        'current_balance': currentBalance,
        'active': active ? 1 : 0,
        'updated_at': updatedAt.toIso8601String(),
      };
}
