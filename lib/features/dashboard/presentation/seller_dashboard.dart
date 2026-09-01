import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../sales/presentation/sales_providers.dart';

class SellerDashboard extends ConsumerWidget {
  final VoidCallback onNavigateToPos;

  const SellerDashboard({
    super.key,
    required this.onNavigateToPos,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentProfile = ref.watch(currentProfileProvider);
    final metrics = ref.watch(currentSellerMetricsProvider);
    final visibleSales = ref.watch(visibleSalesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Seller Terminal', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 19)),
            Text(
              'Logged in: ${currentProfile?.name ?? "Seller"}',
              style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondaryLight),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
        children: [
          // 1. My Sales Today Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryLight, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MY SALES TODAY',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                    letterSpacing: 1,
                  ),
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
                const SizedBox(height: 14),
                Row(
                  children: [
                    _buildSellerMetricPill(
                      icon: Icons.receipt_long_outlined,
                      label: '${metrics.transactionCount} Bills',
                    ),
                    const SizedBox(width: 10),
                    _buildSellerMetricPill(
                      icon: Icons.shopping_bag_outlined,
                      label: '${Formatters.formatQuantity(metrics.totalItemsCount, "")} Items',
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2. Large NEW SALE CTA Button
          ElevatedButton.icon(
            onPressed: onNavigateToPos,
            icon: const Icon(Icons.add_shopping_cart, size: 24),
            label: Text(
              'START NEW SALE',
              style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),

          const SizedBox(height: 20),

          // 3. My Recent Sales
          Text('My Recent Transactions', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (visibleSales.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.shopping_bag_outlined, size: 48, color: AppColors.textSecondaryLight.withValues(alpha: 0.5)),
                    const SizedBox(height: 8),
                    Text(
                      'No sales made by you today yet.\nTap "START NEW SALE" above to begin!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(color: AppColors.textSecondaryLight, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            ...visibleSales.take(5).map((sale) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                Formatters.formatSaleNumber(sale.saleNumber),
                                style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppColors.primary),
                              ),
                              const SizedBox(width: 6),
                              StatusBadge.paymentMethod(sale.paymentMethod),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            Formatters.formatTime(sale.saleDate),
                            style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondaryLight),
                          ),
                        ],
                      ),
                      Text(
                        Formatters.currency(sale.totalAmount),
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimaryLight),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildSellerMetricPill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
