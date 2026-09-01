import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/supabase_service.dart';
import '../domain/stock_movement_model.dart';
import '../../products/data/product_repository.dart';

class StockRepository {
  final ProductRepository _productRepo;
  final _uuid = const Uuid();

  final List<StockMovementModel> _movements = [];
  final _movementsController = StreamController<List<StockMovementModel>>.broadcast();

  StockRepository(this._productRepo) {
    final client = SupabaseService.client;
    if (client != null) {
      _initSupabaseSync();
      getMovements();
    }
  }

  void _initSupabaseSync() {
    final client = SupabaseService.client;
    if (client != null) {
      client
          .channel('public:stock_movements')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'stock_movements',
            callback: (payload) {
              refreshMovements();
            },
          )
          .subscribe();
    }
  }

  Stream<List<StockMovementModel>> get movementsStream {
    Timer.run(() => _movementsController.add(List.unmodifiable(_movements)));
    return _movementsController.stream;
  }

  Future<List<StockMovementModel>> getMovements() async {
    final client = SupabaseService.client;
    if (client != null && client.auth.currentSession != null) {
      try {
        final res = await client
            .from('stock_movements')
            .select('*, products(name, unit), profiles:performed_by(name)')
            .order('created_at', ascending: false);

        final fetched = (res as List).map((e) => StockMovementModel.fromJson(e)).toList();
        _movements.clear();
        _movements.addAll(fetched);
        _movementsController.add(List.unmodifiable(_movements));
        return _movements;
      } catch (e) {
        debugPrint('Error fetching movements from Supabase: $e');
      }
    }
    return List.unmodifiable(_movements);
  }

  Future<void> refreshMovements() async {
    await getMovements();
  }

  /// Receive Inward Stock (Admin authorization enforced)
  Future<void> receiveStock({
    required String productId,
    required String productName,
    required String unit,
    required double quantity,
    required double costPrice,
    String? invoiceNumber,
    String? fallbackUserId,
    String? fallbackUserName,
    String? notes,
  }) async {
    if (quantity <= 0) {
      throw Exception('Quantity must be greater than zero.');
    }

    final client = SupabaseService.client;
    if (client != null && client.auth.currentSession != null) {
      try {
        await client.rpc(
          'receive_stock',
          params: {
            'p_product_id': productId,
            'p_quantity': quantity,
            'p_cost_price': costPrice,
            'p_supplier_id': null,
            'p_invoice_number': invoiceNumber,
            'p_notes': notes,
          },
        );
        await _productRepo.refreshProducts();
        await refreshMovements();
        return;
      } catch (e) {
        debugPrint('Supabase receive_stock error: $e');
        rethrow;
      }
    }

    if (!kDebugMode) {
      throw Exception('Unauthorized: User must be signed in as Admin.');
    }

    // Local in-memory execution for offline test suite
    await _productRepo.updateStockDirectly(productId, quantity);
    final products = await _productRepo.getProducts();
    final product = products.firstWhere((p) => p.id == productId);

    final movement = StockMovementModel(
      id: _uuid.v4(),
      productId: productId,
      movementType: 'purchase',
      quantity: quantity,
      balanceAfter: product.currentStock,
      reason: notes ?? 'Stock Received / Purchase Invoice: ${invoiceNumber ?? 'N/A'}',
      performedBy: fallbackUserId ?? '00000000-0000-0000-0000-000000000001',
      performedByName: fallbackUserName ?? 'Admin',
      productName: productName,
      unit: unit,
      createdAt: DateTime.now(),
    );

    _movements.insert(0, movement);
    _movementsController.add(List.unmodifiable(_movements));
  }

  /// Physical Stock Adjustment (Admin authorization enforced)
  Future<void> adjustStock({
    required String productId,
    required String productName,
    required String unit,
    required double adjustmentDelta,
    String? fallbackUserId,
    String? fallbackUserName,
    required String reason,
  }) async {
    if (reason.trim().isEmpty) {
      throw Exception('Mandatory adjustment reason required.');
    }

    final client = SupabaseService.client;
    if (client != null && client.auth.currentSession != null) {
      try {
        await client.rpc(
          'adjust_stock',
          params: {
            'p_product_id': productId,
            'p_adjustment_delta': adjustmentDelta,
            'p_reason': reason.trim(),
          },
        );
        await _productRepo.refreshProducts();
        await refreshMovements();
        return;
      } catch (e) {
        debugPrint('Supabase adjust_stock error: $e');
        rethrow;
      }
    }

    if (!kDebugMode) {
      throw Exception('Unauthorized: User must be signed in as Admin.');
    }

    // Local in-memory execution for offline test suite
    await _productRepo.updateStockDirectly(productId, adjustmentDelta);
    final products = await _productRepo.getProducts();
    final product = products.firstWhere((p) => p.id == productId);

    final movement = StockMovementModel(
      id: _uuid.v4(),
      productId: productId,
      movementType: 'adjustment',
      quantity: adjustmentDelta,
      balanceAfter: product.currentStock,
      reason: reason,
      performedBy: fallbackUserId ?? '00000000-0000-0000-0000-000000000001',
      performedByName: fallbackUserName ?? 'Admin',
      productName: productName,
      unit: unit,
      createdAt: DateTime.now(),
    );

    _movements.insert(0, movement);
    _movementsController.add(List.unmodifiable(_movements));
  }
}
