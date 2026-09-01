import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/seller_switcher_modal.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../expenses/presentation/expense_providers.dart';
import '../../products/presentation/product_providers.dart';
import '../../sales/presentation/sales_providers.dart';

class AdminDashboard extends ConsumerWidget {
  final VoidCallback onNavigateToPos;
  final VoidCallback onNavigateToStock;

  const AdminDashboard({
    super.key,
    required this.onNavigateToPos,
    required this.onNavigateToStock,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentProfile = ref.watch(currentProfileProvider);
    final metrics = ref.watch(todayStoreMetricsProvider);
    final lowStockProducts = ref.watch(lowStockProductsProvider);
    final todayExpenses = ref.watch(todayExpensesTotalProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Admin Master Dashboard', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 19)),
            Text(
              'Store Manager: ${currentProfile?.name ?? "Admin"}',
              style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondaryLight),
            ),
          ],
        ),
        actions: [
          if (kDebugMode)
            IconButton(
              tooltip: 'Switch User (Debug)',
              icon: const Icon(Icons.bug_report_outlined, color: AppColors.warning),
              onPressed: () => SellerSwitcherModal.show(context),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
        children: [
          // 1. Hero Store Revenue Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TODAY\'S STORE SALES',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                        letterSpacing: 1,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${metrics.transactionCount} Orders',
                        style: GoogleFonts.outfit(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  Formatters.currency(metrics.totalRevenue),
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(color: Colors.white24),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildHeroStat('Items Sold', Formatters.formatQuantity(metrics.totalItemsCount, '')),
                    _buildHeroStat('Gross Margin', Formatters.currency(metrics.grossProfit)),
                    _buildHeroStat('Expenses', Formatters.currency(todayExpenses)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2. Payment Method Distribution
          Text('Today\'s Payment Split', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMetricMiniCard('Cash', Formatters.currency(metrics.cashTotal), Icons.payments_outlined, AppColors.chipCash),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricMiniCard('UPI', Formatters.currency(metrics.upiTotal), Icons.qr_code, AppColors.chipUpi),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricMiniCard('Other', Formatters.currency(metrics.otherTotal), Icons.credit_card, AppColors.chipOther),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 3. Low Stock Radar
          if (lowStockProducts.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('🔴 Low Stock Alerts (${lowStockProducts.length})', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.error)),
                TextButton(
                  onPressed: onNavigateToStock,
                  child: const Text('MANAGE STOCK'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...lowStockProducts.take(3).map((p) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  color: const Color(0xFFFFF3E0),
                  border: const BorderSide(color: AppColors.warning, width: 1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(p.name, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                      Text(
                        '${p.currentStock} / ${p.minimumStock} ${p.unit}',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppColors.error),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
          ],

          // 4. Live Seller Performance Leaderboard
          Text('Live Seller Summary', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: metrics.sellerTotals.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: Center(
                      child: Text('No seller sales recorded today yet', style: GoogleFonts.outfit(color: AppColors.textSecondaryLight)),
                    ),
                  )
                : Column(
                    children: metrics.sellerTotals.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.person_pin, color: AppColors.primary, size: 20),
                                const SizedBox(width: 8),
                                Text(entry.key, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14)),
                              ],
                            ),
                            Text(
                              Formatters.currency(entry.value),
                              style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.primary),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),

          const SizedBox(height: 16),

          // 5. Today's Top Selling Products
          Text('Today\'s Top Products', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: metrics.productSoldQuantities.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: Center(
                      child: Text('No items sold today yet', style: GoogleFonts.outfit(color: AppColors.textSecondaryLight)),
                    ),
                  )
                : Column(
                    children: metrics.productSoldQuantities.entries.take(5).map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(entry.key, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14)),
                            ),
                            Text(
                              '${Formatters.formatQuantity(entry.value, "")} sold',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textSecondaryLight),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.point_of_sale, color: Colors.white),
        label: Text('NEW SALE / POS', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.white)),
        onPressed: onNavigateToPos,
      ),
    );
  }

  Widget _buildHeroStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 11, color: Colors.white70)),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
      ],
    );
  }

  Widget _buildMetricMiniCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(title, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondaryLight)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
