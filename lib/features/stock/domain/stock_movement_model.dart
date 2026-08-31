class StockMovementModel {
  final String id;
  final String productId;
  final String movementType;
  final double quantity;
  final double balanceAfter;
  final String? referenceId;
  final String? reason;
  final String performedBy;
  final DateTime createdAt;

  // Joined fields
  final String? productName;
  final String? unit;
  final String? performedByName;

  StockMovementModel({
    required this.id,
    required this.productId,
    required this.movementType,
    required this.quantity,
    required this.balanceAfter,
    this.referenceId,
    this.reason,
    required this.performedBy,
    required this.createdAt,
    this.productName,
    this.unit,
    this.performedByName,
  });

  bool get isInward => quantity > 0;
  bool get isOutward => quantity < 0;

  factory StockMovementModel.fromJson(Map<String, dynamic> json) {
    return StockMovementModel(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      movementType: json['movement_type'] as String,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      balanceAfter: (json['balance_after'] as num?)?.toDouble() ?? 0.0,
      referenceId: json['reference_id'] as String?,
      reason: json['reason'] as String?,
      performedBy: json['performed_by'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      productName: json['products'] != null ? json['products']['name'] as String? : null,
      unit: json['products'] != null ? json['products']['unit'] as String? : null,
      performedByName: json['profiles'] != null ? json['profiles']['name'] as String? : null,
    );
  }
}
