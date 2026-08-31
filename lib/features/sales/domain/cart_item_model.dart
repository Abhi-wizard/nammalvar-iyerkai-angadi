import '../../products/domain/product_model.dart';

class CartItemModel {
  final ProductModel product;
  double quantity;
  double customRate;

  CartItemModel({
    required this.product,
    this.quantity = 1.0,
    double? rate,
  }) : customRate = rate ?? product.sellingPrice;

  double get amount => double.parse((quantity * customRate).toStringAsFixed(2));

  Map<String, dynamic> toRpcJson() {
    return {
      'product_id': product.id,
      'quantity': quantity,
      'rate': customRate,
    };
  }

  CartItemModel copyWith({
    ProductModel? product,
    double? quantity,
    double? customRate,
  }) {
    return CartItemModel(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      rate: customRate ?? this.customRate,
    );
  }
}
