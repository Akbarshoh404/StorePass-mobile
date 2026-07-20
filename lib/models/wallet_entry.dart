enum WalletEntryKind { earn, redeem, adjustment }

WalletEntryKind walletEntryKindFromString(String value) => switch (value) {
      'redeem' => WalletEntryKind.redeem,
      'adjustment' => WalletEntryKind.adjustment,
      _ => WalletEntryKind.earn,
    };

/// One row of the ledger behind a wallet's balance — `GET /wallets/{shopId}/entries`.
class WalletEntry {
  final int id;
  final WalletEntryKind kind;
  final double delta;
  final double balanceAfter;
  final String? note;
  final DateTime createdAt;

  WalletEntry({
    required this.id,
    required this.kind,
    required this.delta,
    required this.balanceAfter,
    this.note,
    required this.createdAt,
  });

  factory WalletEntry.fromJson(Map<String, dynamic> json) => WalletEntry(
        id: json['id'] as int,
        kind: walletEntryKindFromString(json['kind'] as String),
        delta: (json['delta'] as num).toDouble(),
        balanceAfter: (json['balance_after'] as num).toDouble(),
        note: json['note'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
