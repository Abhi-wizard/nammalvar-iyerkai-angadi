import '../../auth/domain/profile_model.dart';

class SaleItemModel {
  final String id;
  final String saleId;
  final String productId;
  final String productNameSnapshot;
  final String unitSnapshot;
  final double quantity;
  final double rateSnapshot;
  final double costPriceSnapshot;
  final double amount;
  final DateTime createdAt;

  SaleItemModel({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.productNameSnapshot,
    required this.unitSnapshot,
    required this.quantity,
    required this.rateSnapshot,
    this.costPriceSnapshot = 0.0,
    required this.amount,
    required this.createdAt,
  });

  factory SaleItemModel.fromJson(Map<String, dynamic> json) {
    return SaleItemModel(
      id: json['id'] as String,
      saleId: json['sale_id'] as String,
      productId: json['product_id'] as String,
      productNameSnapshot: json['product_name_snapshot'] as String? ?? 'Product',
      unitSnapshot: json['unit_snapshot'] as String? ?? 'piece',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      rateSnapshot: (json['rate_snapshot'] as num?)?.toDouble() ?? 0.0,
      costPriceSnapshot: (json['cost_price_snapshot'] as num?)?.toDouble() ?? 0.0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sale_id': saleId,
      'product_id': productId,
      'product_name_snapshot': productNameSnapshot,
      'unit_snapshot': unitSnapshot,
      'quantity': quantity,
      'rate_snapshot': rateSnapshot,
      'cost_price_snapshot': costPriceSnapshot,
      'amount': amount,
    };
  }
}

class SaleModel {
  final String id;
  final int saleNumber;
  final String sellerId;
  final DateTime saleDate;
  final double totalAmount;
  final double totalCostAmount;
  final String paymentMethod;
  final String status;
  final String? cancelledBy;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final DateTime createdAt;

  // Joined fields
  final String? sellerName;
  final String? cancelledByName;
  final List<SaleItemModel> items;

  SaleModel({
    required this.id,
    required this.saleNumber,
    required this.sellerId,
    required this.saleDate,
    required this.totalAmount,
    this.totalCostAmount = 0.0,
    required this.paymentMethod,
    this.status = 'completed',
    this.cancelledBy,
    this.cancelledAt,
    this.cancellationReason,
    required this.createdAt,
    this.sellerName,
    this.cancelledByName,
    this.items = const [],
  });

  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  factory SaleModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['sale_items'] as List<dynamic>? ?? [];
    List<SaleItemModel> parsedItems = rawItems
        .map((e) => SaleItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final profileMap = json['profiles'] as Map<String, dynamic>?;
    final rawSellerName = profileMap != null ? profileMap['name'] as String? : null;
    final rawSellerEmail = profileMap != null ? profileMap['email'] as String? : null;

    final cancelledProfileMap = json['cancelled_by_profile'] as Map<String, dynamic>?;
    final rawCancelledName = cancelledProfileMap != null ? cancelledProfileMap['name'] as String? : null;
    final rawCancelledEmail = cancelledProfileMap != null ? cancelledProfileMap['email'] as String? : null;

    return SaleModel(
      id: json['id'] as String,
      saleNumber: json['sale_number'] as int? ?? 0,
      sellerId: json['seller_id'] as String,
      saleDate: json['sale_date'] != null
          ? DateTime.parse(json['sale_date'] as String).toLocal()
          : DateTime.now(),
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      totalCostAmount: (json['total_cost_amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      status: json['status'] as String? ?? 'completed',
      cancelledBy: json['cancelled_by'] as String?,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'] as String).toLocal()
          : null,
      cancellationReason: json['cancellation_reason'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : DateTime.now(),
      sellerName: ProfileModel.normalizeDisplayName(rawSellerName, rawSellerEmail),
      cancelledByName: ProfileModel.normalizeDisplayName(rawCancelledName, rawCancelledEmail),
      items: parsedItems,
    );
  }

  SaleModel copyWith({
    String? id,
    int? saleNumber,
    String? sellerId,
    DateTime? saleDate,
    double? totalAmount,
    double? totalCostAmount,
    String? paymentMethod,
    String? status,
    String? cancelledBy,
    DateTime? cancelledAt,
    String? cancellationReason,
    DateTime? createdAt,
    String? sellerName,
    String? cancelledByName,
    List<SaleItemModel>? items,
  }) {
    return SaleModel(
      id: id ?? this.id,
      saleNumber: saleNumber ?? this.saleNumber,
      sellerId: sellerId ?? this.sellerId,
      saleDate: saleDate ?? this.saleDate,
      totalAmount: totalAmount ?? this.totalAmount,
      totalCostAmount: totalCostAmount ?? this.totalCostAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      createdAt: createdAt ?? this.createdAt,
      sellerName: sellerName ?? this.sellerName,
      cancelledByName: cancelledByName ?? this.cancelledByName,
      items: items ?? this.items,
    );
  }
}
