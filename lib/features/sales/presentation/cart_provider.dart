import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../products/domain/product_model.dart';
import '../domain/cart_item_model.dart';

class CartNotifier extends StateNotifier<List<CartItemModel>> {
  CartNotifier() : super([]);

  void addProduct(ProductModel product, {double quantity = 1.0}) {
    final existingIndex = state.indexWhere((item) => item.product.id == product.id);

    if (existingIndex != -1) {
      final current = state[existingIndex];
      final newQty = current.quantity + quantity;
      final updatedList = List<CartItemModel>.from(state);
      updatedList[existingIndex] = current.copyWith(quantity: newQty);
      state = updatedList;
    } else {
      state = [
        ...state,
        CartItemModel(product: product, quantity: quantity),
      ];
    }
  }

  void updateQuantity(String productId, double quantity) {
    if (quantity <= 0) {
      removeProduct(productId);
      return;
    }
    final existingIndex = state.indexWhere((item) => item.product.id == productId);
    if (existingIndex != -1) {
      final updatedList = List<CartItemModel>.from(state);
      updatedList[existingIndex] = updatedList[existingIndex].copyWith(quantity: quantity);
      state = updatedList;
    }
  }

  void updateRate(String productId, double rate) {
    final existingIndex = state.indexWhere((item) => item.product.id == productId);
    if (existingIndex != -1) {
      final updatedList = List<CartItemModel>.from(state);
      updatedList[existingIndex] = updatedList[existingIndex].copyWith(customRate: rate);
      state = updatedList;
    }
  }

  void removeProduct(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  void clearCart() {
    state = [];
  }

  double get totalAmount {
    return state.fold(0.0, (sum, item) => sum + item.amount);
  }

  int get totalItemCount {
    return state.length;
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItemModel>>((ref) {
  return CartNotifier();
});

// Selected Payment Method for POS
final selectedPaymentMethodProvider = StateProvider<String>((ref) => 'cash');
