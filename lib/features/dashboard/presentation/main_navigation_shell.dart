import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../expenses/presentation/expenses_screen.dart';
import '../../products/presentation/products_screen.dart';
import '../../reports/presentation/reports_screen.dart';
import '../../sales/presentation/new_sale_screen.dart';
import '../../sales/presentation/sales_history_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../stock/presentation/stock_screen.dart';
import 'admin_dashboard.dart';
import 'seller_dashboard.dart';

class MainNavigationShell extends ConsumerStatefulWidget {
  const MainNavigationShell({super.key});

  @override
  ConsumerState<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  int _selectedIndex = 0;

  void _navigateToIndex(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final currentProfile = ref.watch(currentProfileProvider);
    final isAdmin = currentProfile?.isAdmin == true;

    // Admin Screens
    final adminScreens = [
      AdminDashboard(
        onNavigateToPos: () => _navigateToIndex(1),
        onNavigateToStock: () => _navigateToIndex(3),
      ),
      const NewSaleScreen(),
      const ProductsScreen(),
      const StockScreen(),
      const SalesHistoryScreen(),
      const ReportsScreen(),
      const ExpensesScreen(),
      const SettingsScreen(),
    ];

    // Seller Screens
    final sellerScreens = [
      SellerDashboard(
        onNavigateToPos: () => _navigateToIndex(1),
      ),
      const NewSaleScreen(),
      const ProductsScreen(),
      const SalesHistoryScreen(),
      const SettingsScreen(),
    ];

    final screens = isAdmin ? adminScreens : sellerScreens;
    final safeIndex = _selectedIndex < screens.length ? _selectedIndex : 0;

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: safeIndex,
          onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
          backgroundColor: AppColors.surfaceLight,
          indicatorColor: AppColors.primaryContainer,
          elevation: 0,
          destinations: isAdmin
              ? const [
                  NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard, color: AppColors.primary), label: 'Home'),
                  NavigationDestination(icon: Icon(Icons.point_of_sale_outlined), selectedIcon: Icon(Icons.point_of_sale, color: AppColors.primary), label: 'POS'),
                  NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2, color: AppColors.primary), label: 'Products'),
                  NavigationDestination(icon: Icon(Icons.storage_outlined), selectedIcon: Icon(Icons.storage, color: AppColors.primary), label: 'Stock'),
                  NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long, color: AppColors.primary), label: 'Sales'),
                  NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart, color: AppColors.primary), label: 'Reports'),
                  NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet, color: AppColors.primary), label: 'Expenses'),
                  NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings, color: AppColors.primary), label: 'Settings'),
                ]
              : const [
                  NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: AppColors.primary), label: 'Home'),
                  NavigationDestination(icon: Icon(Icons.point_of_sale_outlined), selectedIcon: Icon(Icons.point_of_sale, color: AppColors.primary), label: 'New Sale'),
                  NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2, color: AppColors.primary), label: 'Catalog'),
                  NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long, color: AppColors.primary), label: 'My Sales'),
                  NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings, color: AppColors.primary), label: 'Settings'),
                ],
        ),
      ),
    );
  }
}
