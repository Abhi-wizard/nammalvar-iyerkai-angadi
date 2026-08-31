import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/supabase_service.dart';
import '../domain/cart_item_model.dart';
import '../domain/sale_model.dart';
import '../../products/data/product_repository.dart';

class SalesRepository {
  final ProductRepository _productRepo;
  final _uuid = const Uuid();

  final List<SaleModel> _sales = [];
  final _salesController = StreamController<List<SaleModel>>.broadcast();
  int _localSaleSequence = 1001;

  SalesRepository(this._productRepo) {
    if (kDebugMode) {
      _seedInitialSales();
    }
    _initSupabaseSync();
  }

  void _seedInitialSales() {
    final now = DateTime.now();
    _sales.add(
      SaleModel(
        id: 'sale-1001',
        saleNumber: 1001,
        sellerId: '00000000-0000-0000-0000-000000000002',
        sellerName: 'Seller 1 (Murugan)',
        saleDate: now.subtract(const Duration(hours: 3)),
        totalAmount: 300.0,
        totalCostAmount: 210.0,
        paymentMethod: 'cash',
        status: 'completed',
        createdAt: now.subtract(const Duration(hours: 3)),
        items: [
          SaleItemModel(
            id: 'item-1',
            saleId: 'sale-1001',
            productId: 'prod-23',
            productNameSnapshot: 'Sembaruthi Shampoo',
            unitSnapshot: 'bottle',
            quantity: 2.0,
            rateSnapshot: 150.0,
            costPriceSnapshot: 105.0,
            amount: 300.0,
            createdAt: now.subtract(const Duration(hours: 3)),
          ),
        ],
      ),
    );

    _sales.add(
      SaleModel(
        id: 'sale-1002',
        saleNumber: 1002,
        sellerId: '00000000-0000-0000-0000-000000000003',
        sellerName: 'Seller 2 (Kavitha)',
        saleDate: now.subtract(const Duration(hours: 2)),
        totalAmount: 240.0,
        totalCostAmount: 165.0,
        paymentMethod: 'upi',
        status: 'completed',
        createdAt: now.subtract(const Duration(hours: 2)),
        items: [
          SaleItemModel(
            id: 'item-2',
            saleId: 'sale-1002',
            productId: 'prod-10',
            productNameSnapshot: 'Vetiver Soap',
            unitSnapshot: 'piece',
            quantity: 3.0,
            rateSnapshot: 80.0,
            costPriceSnapshot: 55.0,
            amount: 240.0,
            createdAt: now.subtract(const Duration(hours: 2)),
          ),
        ],
      ),
    );

    _localSaleSequence = 1003;
  }

  void _initSupabaseSync() {
    final client = SupabaseService.client;
    if (client != null) {
      client
          .channel('public:sales')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'sales',
            callback: (payload) {
              refreshSales();
            },
          )
          .subscribe();
    }
  }

  Stream<List<SaleModel>> get salesStream {
    Timer.run(() => _salesController.add(List.unmodifiable(_sales)));
    return _salesController.stream;
  }

  Future<List<SaleModel>> getSales() async {
    final client = SupabaseService.client;
    if (client != null && client.auth.currentSession != null) {
      try {
        final res = await client
            .from('sales')
            .select('*, profiles:seller_id(name), cancelled_by_profile:cancelled_by(name), sale_items(*)')
            .order('created_at', ascending: false);

        final fetched = (res as List).map((e) => SaleModel.fromJson(e)).toList();
        _sales.clear();
        _sales.addAll(fetched);
        _salesController.add(List.unmodifiable(_sales));
        return _sales;
      } catch (e) {
        debugPrint('Error fetching sales from Supabase: $e');
      }
    }
    return List.unmodifiable(_sales);
  }

  Future<void> refreshSales() async {
    await getSales();
  }

  /// Secure Atomic Sale Processing
  Future<SaleModel> processSale({
    required String paymentMethod,
    required List<CartItemModel> cartItems,
    String? fallbackSellerId,
    String? fallbackSellerName,
  }) async {
    if (cartItems.isEmpty) {
      throw Exception('Cart is empty. Add at least one item.');
    }

    final client = SupabaseService.client;
    if (client != null && client.auth.currentSession != null) {
      try {
        final itemsPayload = cartItems.map((item) => item.toRpcJson()).toList();

        // Server-side RPC derives seller from auth.uid()
        final saleId = await client.rpc(
          'process_sale',
          params: {
            'p_payment_method': paymentMethod,
            'p_items': itemsPayload,
          },
        );

        await _productRepo.refreshProducts();
        await refreshSales();

        return _sales.firstWhere((s) => s.id == saleId.toString());
      } catch (e) {
        debugPrint('Supabase process_sale error: $e');
        rethrow;
      }
    }

    if (!kDebugMode) {
      throw Exception('Unauthorized: User must be signed in to perform sales.');
    }

    // Local / Debug mode fallback
    final sellerId = fallbackSellerId ?? '00000000-0000-0000-0000-000000000002';
    final sellerName = fallbackSellerName ?? 'Debug Seller';

    double totalAmount = 0;
    double totalCost = 0;
    final List<SaleItemModel> saleItems = [];
    final saleId = 'sale-$_localSaleSequence';

    for (final item in cartItems) {
      if (item.product.currentStock < item.quantity) {
        throw Exception(
          'Insufficient stock for "${item.product.name}". Requested: ${item.quantity} ${item.product.unit}, Available: ${item.product.currentStock} ${item.product.unit}',
        );
      }

      totalAmount += item.amount;
      totalCost += (item.quantity * item.product.costPrice);

      saleItems.add(
        SaleItemModel(
          id: 'item-${_uuid.v4().substring(0, 8)}',
          saleId: saleId,
          productId: item.product.id,
          productNameSnapshot: item.product.name,
          unitSnapshot: item.product.unit,
          quantity: item.quantity,
          rateSnapshot: item.customRate,
          costPriceSnapshot: item.product.costPrice,
          amount: item.amount,
          createdAt: DateTime.now(),
        ),
      );

      await _productRepo.updateStockDirectly(item.product.id, -item.quantity);
    }

    final newSale = SaleModel(
      id: saleId,
      saleNumber: _localSaleSequence++,
      sellerId: sellerId,
      sellerName: sellerName,
      saleDate: DateTime.now(),
      totalAmount: totalAmount,
      totalCostAmount: totalCost,
      paymentMethod: paymentMethod,
      status: 'completed',
      createdAt: DateTime.now(),
      items: saleItems,
    );

    _sales.insert(0, newSale);
    _salesController.add(List.unmodifiable(_sales));
    return newSale;
  }

  /// Secure Atomic Sale Cancellation
  Future<bool> cancelSale({
    required String saleId,
    required String reason,
    String? fallbackAdminId,
    String? fallbackAdminName,
  }) async {
    if (reason.trim().isEmpty) {
      throw Exception('Mandatory cancellation reason required.');
    }

    final client = SupabaseService.client;
    if (client != null && client.auth.currentSession != null) {
      try {
        await client.rpc(
          'cancel_sale',
          params: {
            'p_sale_id': saleId,
            'p_reason': reason.trim(),
          },
        );
        await _productRepo.refreshProducts();
        await refreshSales();
        return true;
      } catch (e) {
        debugPrint('Supabase cancel_sale error: $e');
        rethrow;
      }
    }

    if (!kDebugMode) {
      throw Exception('Unauthorized: User must be signed in as Admin.');
    }

    final index = _sales.indexWhere((s) => s.id == saleId);
    if (index == -1) {
      throw Exception('Sale not found.');
    }

    final sale = _sales[index];
    if (sale.isCancelled) {
      throw Exception('Sale is already cancelled.');
    }

    for (final item in sale.items) {
      await _productRepo.updateStockDirectly(item.productId, item.quantity);
    }

    final cancelledSale = sale.copyWith(
      status: 'cancelled',
      cancelledBy: fallbackAdminId ?? '00000000-0000-0000-0000-000000000001',
      cancelledByName: fallbackAdminName ?? 'Admin',
      cancelledAt: DateTime.now(),
      cancellationReason: reason,
    );

    _sales[index] = cancelledSale;
    _salesController.add(List.unmodifiable(_sales));
    return true;
  }
}
