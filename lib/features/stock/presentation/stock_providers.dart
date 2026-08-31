import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/stock_repository.dart';
import '../domain/stock_movement_model.dart';
import '../../products/presentation/product_providers.dart';

final stockRepositoryProvider = Provider<StockRepository>((ref) {
  final productRepo = ref.watch(productRepositoryProvider);
  return StockRepository(productRepo);
});

final stockMovementsStreamProvider = StreamProvider<List<StockMovementModel>>((ref) {
  final repo = ref.watch(stockRepositoryProvider);
  return repo.movementsStream;
});

// Filter stock movements by selected product ID
final stockMovementProductFilterProvider = StateProvider<String?>((ref) => null);

final filteredStockMovementsProvider = Provider<List<StockMovementModel>>((ref) {
  final movementsAsync = ref.watch(stockMovementsStreamProvider);
  final productFilter = ref.watch(stockMovementProductFilterProvider);

  return movementsAsync.maybeWhen(
    data: (movements) {
      if (productFilter == null || productFilter.isEmpty) return movements;
      return movements.where((m) => m.productId == productFilter).toList();
    },
    orElse: () => [],
  );
});
