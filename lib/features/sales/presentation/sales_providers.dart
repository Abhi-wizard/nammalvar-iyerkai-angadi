import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/sales_repository.dart';
import '../domain/sale_model.dart';
import '../../products/presentation/product_providers.dart';
import '../../auth/presentation/auth_providers.dart';

final salesRepositoryProvider = Provider<SalesRepository>((ref) {
  final productRepo = ref.watch(productRepositoryProvider);
  final repo = SalesRepository(productRepo);
  ref.onDispose(() {
    repo.dispose();
  });
  return repo;
});

final salesStreamProvider = StreamProvider<List<SaleModel>>((ref) {
  final repo = ref.watch(salesRepositoryProvider);
  return repo.salesStream;
});

// Sales Filters
final salesFilterPaymentMethodProvider = StateProvider<String?>((ref) => null);
final salesFilterSellerIdProvider = StateProvider<String?>((ref) => null);
final salesFilterDateProvider = StateProvider<DateTime?>((ref) => null);

// Filtered Sales List (handles Admin vs Seller permissions)
final visibleSalesProvider = Provider<List<SaleModel>>((ref) {
  final salesAsync = ref.watch(salesStreamProvider);
  final currentProfile = ref.watch(currentProfileProvider);
  final paymentFilter = ref.watch(salesFilterPaymentMethodProvider);
  final sellerFilter = ref.watch(salesFilterSellerIdProvider);
  final dateFilter = ref.watch(salesFilterDateProvider);

  return salesAsync.maybeWhen(
    data: (sales) {
      return sales.where((sale) {
        // If current user is a Seller, only show their own sales
        if (currentProfile != null && currentProfile.isSeller) {
          if (sale.sellerId != currentProfile.id) {
            return false;
          }
        } else if (sellerFilter != null && sellerFilter.isNotEmpty) {
          if (sale.sellerId != sellerFilter) {
            return false;
          }
        }

        // Payment method filter
        if (paymentFilter != null && paymentFilter.isNotEmpty) {
          if (sale.paymentMethod.toLowerCase() != paymentFilter.toLowerCase()) {
            return false;
          }
        }

        // Date filter (local timezone match)
        if (dateFilter != null) {
          final sDate = sale.saleDate.toLocal();
          final dDate = dateFilter.toLocal();
          if (sDate.year != dDate.year ||
              sDate.month != dDate.month ||
              sDate.day != dDate.day) {
            return false;
          }
        }

        return true;
      }).toList();
    },
    orElse: () => [],
  );
});

// Today's Sales Dashboard Metrics
class StoreMetrics {
  final double totalRevenue;
  final double totalCost;
  final int transactionCount;
  final double totalItemsCount;
  final double cashTotal;
  final double upiTotal;
  final double otherTotal;
  final Map<String, double> sellerTotals;
  final Map<String, double> productSoldQuantities;
  final Map<String, double> productSoldRevenues;

  StoreMetrics({
    this.totalRevenue = 0,
    this.totalCost = 0,
    this.transactionCount = 0,
    this.totalItemsCount = 0,
    this.cashTotal = 0,
    this.upiTotal = 0,
    this.otherTotal = 0,
    this.sellerTotals = const {},
    this.productSoldQuantities = const {},
    this.productSoldRevenues = const {},
  });

  double get grossProfit => totalRevenue - totalCost;
}

final todayStoreMetricsProvider = Provider<StoreMetrics>((ref) {
  final salesAsync = ref.watch(salesStreamProvider);
  final now = DateTime.now(); // local device time

  return salesAsync.maybeWhen(
    data: (sales) {
      double totalRev = 0;
      double totalCost = 0;
      int count = 0;
      double itemsCount = 0;
      double cash = 0;
      double upi = 0;
      double other = 0;
      final Map<String, double> sellerMap = {};
      final Map<String, double> prodQtyMap = {};
      final Map<String, double> prodRevMap = {};

      for (final sale in sales) {
        if (!sale.isCompleted) continue; // ignore cancelled sales for revenue

        final sDate = sale.saleDate.toLocal();
        final isToday = sDate.year == now.year && sDate.month == now.month && sDate.day == now.day;

        if (isToday) {
          totalRev += sale.totalAmount;
          totalCost += sale.totalCostAmount;
          count++;

          if (sale.paymentMethod == 'cash') cash += sale.totalAmount;
          if (sale.paymentMethod == 'upi') upi += sale.totalAmount;
          if (sale.paymentMethod == 'other') other += sale.totalAmount;

          final sellerName = sale.sellerName ?? 'Seller';
          sellerMap[sellerName] = (sellerMap[sellerName] ?? 0) + sale.totalAmount;

          for (final item in sale.items) {
            itemsCount += item.quantity;
            prodQtyMap[item.productNameSnapshot] = (prodQtyMap[item.productNameSnapshot] ?? 0) + item.quantity;
            prodRevMap[item.productNameSnapshot] = (prodRevMap[item.productNameSnapshot] ?? 0) + item.amount;
          }
        }
      }

      return StoreMetrics(
        totalRevenue: totalRev,
        totalCost: totalCost,
        transactionCount: count,
        totalItemsCount: itemsCount,
        cashTotal: cash,
        upiTotal: upi,
        otherTotal: other,
        sellerTotals: sellerMap,
        productSoldQuantities: prodQtyMap,
        productSoldRevenues: prodRevMap,
      );
    },
    orElse: () => StoreMetrics(),
  );
});

// Logged-in Seller Personal Daily Metrics
final currentSellerMetricsProvider = Provider<StoreMetrics>((ref) {
  final salesAsync = ref.watch(salesStreamProvider);
  final currentProfile = ref.watch(currentProfileProvider);
  final now = DateTime.now();

  if (currentProfile == null) return StoreMetrics();

  return salesAsync.maybeWhen(
    data: (sales) {
      double totalRev = 0;
      double totalCost = 0;
      int count = 0;
      double itemsCount = 0;
      double cash = 0;
      double upi = 0;
      double other = 0;
      final Map<String, double> prodQtyMap = {};
      final Map<String, double> prodRevMap = {};

      for (final sale in sales) {
        if (!sale.isCompleted) continue;
        if (sale.sellerId != currentProfile.id) continue;

        final sDate = sale.saleDate.toLocal();
        final isToday = sDate.year == now.year && sDate.month == now.month && sDate.day == now.day;

        if (isToday) {
          totalRev += sale.totalAmount;
          totalCost += sale.totalCostAmount;
          count++;

          if (sale.paymentMethod == 'cash') cash += sale.totalAmount;
          if (sale.paymentMethod == 'upi') upi += sale.totalAmount;
          if (sale.paymentMethod == 'other') other += sale.totalAmount;

          for (final item in sale.items) {
            itemsCount += item.quantity;
            prodQtyMap[item.productNameSnapshot] = (prodQtyMap[item.productNameSnapshot] ?? 0) + item.quantity;
            prodRevMap[item.productNameSnapshot] = (prodRevMap[item.productNameSnapshot] ?? 0) + item.amount;
          }
        }
      }

      return StoreMetrics(
        totalRevenue: totalRev,
        totalCost: totalCost,
        transactionCount: count,
        totalItemsCount: itemsCount,
        cashTotal: cash,
        upiTotal: upi,
        otherTotal: other,
        productSoldQuantities: prodQtyMap,
        productSoldRevenues: prodRevMap,
      );
    },
    orElse: () => StoreMetrics(),
  );
});
