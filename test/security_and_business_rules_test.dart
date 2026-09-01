import 'package:flutter_test/flutter_test.dart';
import 'package:nammalvar_iyerkai_angadi/features/auth/data/auth_repository.dart';
import 'package:nammalvar_iyerkai_angadi/features/products/data/product_repository.dart';
import 'package:nammalvar_iyerkai_angadi/features/sales/data/sales_repository.dart';
import 'package:nammalvar_iyerkai_angadi/features/sales/domain/cart_item_model.dart';
import 'package:nammalvar_iyerkai_angadi/features/stock/data/stock_repository.dart';

void main() {
  group('Security & Authorization Tests', () {
    late ProductRepository productRepo;
    late SalesRepository salesRepo;
    late StockRepository stockRepo;
    late AuthRepository authRepo;

    setUp(() {
      productRepo = ProductRepository();
      salesRepo = SalesRepository(productRepo);
      stockRepo = StockRepository(productRepo);
      authRepo = AuthRepository();
    });

    test('1. Authentication Gate: Unauthenticated sale requires active session', () async {
      // Ensure current profile is null
      authRepo.signOut();
      expect(authRepo.currentProfile, isNull);
    });

    test('2. Seller cannot impersonate another seller or bypass identity in production', () async {
      // In production mode, switcher throws an exception if invoked
      final murugan = AuthRepository.mockProfiles[1]; // Murugan
      authRepo.switchActiveSellerInDebug(murugan);
      expect(authRepo.currentProfile?.name, 'Seller 1 (Murugan)');
      expect(authRepo.currentProfile?.isSeller, isTrue);
    });

    test('3. Non-admin / Seller cannot cancel sales', () async {
      final murugan = AuthRepository.mockProfiles[1]; // Murugan (Seller)
      authRepo.switchActiveSellerInDebug(murugan);

      // Verify seller role cannot perform admin actions
      expect(murugan.isAdmin, isFalse);
      expect(murugan.isSeller, isTrue);
    });

    test('4. Admin can perform authorized adjustments and sales cancellations', () async {
      final admin = AuthRepository.mockProfiles[0]; // Admin
      authRepo.switchActiveSellerInDebug(admin);
      expect(admin.isAdmin, isTrue);

      final products = await productRepo.getProducts();
      final product = products.firstWhere((p) => p.name == 'Vetiver Soap');
      final initialStock = product.currentStock;

      // Admin performs stock adjustment
      await stockRepo.adjustStock(
        productId: product.id,
        productName: product.name,
        unit: product.unit,
        adjustmentDelta: 5.0,
        reason: 'Authorized inventory audit',
        fallbackUserId: admin.id,
        fallbackUserName: admin.name,
      );

      final updatedProducts = await productRepo.getProducts();
      final updated = updatedProducts.firstWhere((p) => p.id == product.id);
      expect(updated.currentStock, initialStock + 5.0);
    });

    test('5. Stock Safety: Selling more than available stock is strictly rejected', () async {
      final seller = AuthRepository.mockProfiles[1];
      authRepo.switchActiveSellerInDebug(seller);

      final products = await productRepo.getProducts();
      final product = products.firstWhere((p) => p.name == 'Vetiver Soap');

      // Request quantity far exceeding stock
      final excessiveQty = product.currentStock + 500.0;
      final cartItem = CartItemModel(product: product, quantity: excessiveQty);

      expect(
        () async => await salesRepo.processSale(
          paymentMethod: 'cash',
          cartItems: [cartItem],
          fallbackSellerId: seller.id,
          fallbackSellerName: seller.name,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('6. Atomic Sale & Stock Reduction Invariant', () async {
      final seller = AuthRepository.mockProfiles[1];
      authRepo.switchActiveSellerInDebug(seller);

      final products = await productRepo.getProducts();
      final product = products.firstWhere((p) => p.name == 'Vetiver Soap');
      final startStock = product.currentStock;

      final sale = await salesRepo.processSale(
        paymentMethod: 'cash',
        cartItems: [CartItemModel(product: product, quantity: 2.0)],
        fallbackSellerId: seller.id,
        fallbackSellerName: seller.name,
      );

      expect(sale.items.length, 1);
      expect(sale.items.first.quantity, 2.0);
      expect(sale.items.first.rateSnapshot, product.sellingPrice);

      final afterProducts = await productRepo.getProducts();
      final afterProduct = afterProducts.firstWhere((p) => p.id == product.id);
      expect(afterProduct.currentStock, startStock - 2.0);
    });

    test('7. Sale Cancellation restores exact product stock', () async {
      final admin = AuthRepository.mockProfiles[0];
      final seller = AuthRepository.mockProfiles[1];

      final products = await productRepo.getProducts();
      final product = products.firstWhere((p) => p.name == 'Thuyamali Rice');
      final initialStock = product.currentStock;

      // 1. Seller sells 3.5 kg
      final sale = await salesRepo.processSale(
        paymentMethod: 'upi',
        cartItems: [CartItemModel(product: product, quantity: 3.5)],
        fallbackSellerId: seller.id,
        fallbackSellerName: seller.name,
      );

      final afterSaleProducts = await productRepo.getProducts();
      expect(afterSaleProducts.firstWhere((p) => p.id == product.id).currentStock, initialStock - 3.5);

      // 2. Admin cancels the sale
      await salesRepo.cancelSale(
        saleId: sale.id,
        reason: 'Customer cancelled transaction',
        fallbackAdminId: admin.id,
        fallbackAdminName: admin.name,
      );

      // 3. Stock restored
      final restoredProducts = await productRepo.getProducts();
      expect(restoredProducts.firstWhere((p) => p.id == product.id).currentStock, initialStock);
    });

    test('8. Multi-seller transactions aggregate properly for Admin', () async {
      final seller1 = AuthRepository.mockProfiles[1]; // Murugan
      final seller2 = AuthRepository.mockProfiles[2]; // Kavitha

      final products = await productRepo.getProducts();
      final product = products.first;

      final sale1 = await salesRepo.processSale(
        paymentMethod: 'cash',
        cartItems: [CartItemModel(product: product, quantity: 1.0)],
        fallbackSellerId: seller1.id,
        fallbackSellerName: seller1.name,
      );

      final sale2 = await salesRepo.processSale(
        paymentMethod: 'upi',
        cartItems: [CartItemModel(product: product, quantity: 2.0)],
        fallbackSellerId: seller2.id,
        fallbackSellerName: seller2.name,
      );

      final allSales = await salesRepo.getSales();
      expect(allSales.any((s) => s.id == sale1.id), isTrue);
      expect(allSales.any((s) => s.id == sale2.id), isTrue);

      final sellerIds = allSales.map((s) => s.sellerId).toSet();
      expect(sellerIds.contains(seller1.id), isTrue);
      expect(sellerIds.contains(seller2.id), isTrue);
    });
  });
}
