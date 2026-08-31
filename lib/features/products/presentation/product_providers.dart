import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/product_repository.dart';
import '../domain/category_model.dart';
import '../domain/product_model.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

final productsStreamProvider = StreamProvider<List<ProductModel>>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  return repo.productsStream;
});

final categoriesStreamProvider = StreamProvider<List<CategoryModel>>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  return repo.categoriesStream;
});

// Selected Category Filter for Product list & POS
final selectedCategoryFilterProvider = StateProvider<String?>((ref) => null);

// Product Search Query
final productSearchQueryProvider = StateProvider<String>((ref) => '');

// Filtered Products Provider
final filteredProductsProvider = Provider<List<ProductModel>>((ref) {
  final productsAsync = ref.watch(productsStreamProvider);
  final selectedCat = ref.watch(selectedCategoryFilterProvider);
  final query = ref.watch(productSearchQueryProvider).toLowerCase().trim();

  return productsAsync.maybeWhen(
    data: (products) {
      return products.where((p) {
        if (!p.isActive) return false;

        // Category filter
        if (selectedCat != null && selectedCat.isNotEmpty) {
          if (p.categoryId != selectedCat && p.subcategoryId != selectedCat) {
            return false;
          }
        }

        // Search query filter
        if (query.isNotEmpty) {
          final matchesName = p.name.toLowerCase().contains(query);
          final matchesBrand = (p.brand ?? '').toLowerCase().contains(query);
          final matchesCat = (p.categoryName ?? '').toLowerCase().contains(query);
          final matchesSub = (p.subcategoryName ?? '').toLowerCase().contains(query);
          if (!matchesName && !matchesBrand && !matchesCat && !matchesSub) {
            return false;
          }
        }

        return true;
      }).toList();
    },
    orElse: () => [],
  );
});

// Low Stock Products Provider
final lowStockProductsProvider = Provider<List<ProductModel>>((ref) {
  final productsAsync = ref.watch(productsStreamProvider);
  return productsAsync.maybeWhen(
    data: (products) => products.where((p) => p.isActive && p.isLowStock).toList(),
    orElse: () => [],
  );
});
