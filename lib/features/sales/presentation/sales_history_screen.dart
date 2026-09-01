import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/presentation/auth_providers.dart';
import '../domain/sale_model.dart';
import 'sales_providers.dart';

class SalesHistoryScreen extends ConsumerWidget {
  const SalesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentProfile = ref.watch(currentProfileProvider);
    final visibleSales = ref.watch(visibleSalesProvider);
    final paymentFilter = ref.watch(salesFilterPaymentMethodProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          currentProfile?.isSeller == true ? 'My Sales History' : 'Store Sales History',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips (Payment method, All)
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                FilterChip(
                  label: const Text('All Payments'),
                  selected: paymentFilter == null,
                  onSelected: (_) => ref.read(salesFilterPaymentMethodProvider.notifier).state = null,
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Cash'),
                  selected: paymentFilter == 'cash',
                  onSelected: (_) => ref.read(salesFilterPaymentMethodProvider.notifier).state =
                      paymentFilter == 'cash' ? null : 'cash',
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('UPI'),
                  selected: paymentFilter == 'upi',
                  onSelected: (_) => ref.read(salesFilterPaymentMethodProvider.notifier).state =
                      paymentFilter == 'upi' ? null : 'upi',
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Other'),
                  selected: paymentFilter == 'other',
                  onSelected: (_) => ref.read(salesFilterPaymentMethodProvider.notifier).state =
                      paymentFilter == 'other' ? null : 'other',
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Sales List
          Expanded(
            child: visibleSales.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textSecondaryLight.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        Text(
                          'No sales recorded',
                          style: GoogleFonts.outfit(fontSize: 16, color: AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    itemCount: visibleSales.length,
                    itemBuilder: (context, index) {
                      final sale = visibleSales[index];
                      return _buildSaleCard(context, ref, sale, currentProfile);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleCard(
    BuildContext context,
    WidgetRef ref,
    SaleModel sale,
    dynamic currentProfile,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: () => _showSaleDetailsModal(context, ref, sale, currentProfile),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      Formatters.formatSaleNumber(sale.saleNumber),
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge.paymentMethod(sale.paymentMethod),
                    const SizedBox(width: 6),
                    StatusBadge.saleStatus(sale.status),
                  ],
                ),
                Text(
                  Formatters.currency(sale.totalAmount),
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: sale.isCancelled ? AppColors.textSecondaryLight : AppColors.primary,
                    decoration: sale.isCancelled ? TextDecoration.lineThrough : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sold by: ${sale.sellerName ?? "Seller"}',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                Text(
                  Formatters.formatDateTime(sale.saleDate),
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
            if (sale.items.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                sale.items
                    .map((item) => '${item.productNameSnapshot} (${Formatters.formatQuantity(item.quantity, item.unitSnapshot)})')
                    .join(', '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
            if (sale.isCancelled && sale.cancellationReason != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Reason: ${sale.cancellationReason}',
                  style: GoogleFonts.outfit(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSaleDetailsModal(
    BuildContext context,
    WidgetRef ref,
    SaleModel sale,
    dynamic currentProfile,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SaleDetailsSheet(
        sale: sale,
        currentProfile: currentProfile,
      ),
    );
  }
}

class _SaleDetailsSheet extends ConsumerStatefulWidget {
  final SaleModel sale;
  final dynamic currentProfile;

  const _SaleDetailsSheet({
    required this.sale,
    required this.currentProfile,
  });

  @override
  ConsumerState<_SaleDetailsSheet> createState() => _SaleDetailsSheetState();
}

class _SaleDetailsSheetState extends ConsumerState<_SaleDetailsSheet> {
  void _showCancelConfirmation() {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cancel Sale ${Formatters.formatSaleNumber(widget.sale.saleNumber)}?', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cancelling this sale will permanently mark it as cancelled, reverse the revenue figures, and automatically restore the sold quantities back into stock.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Mandatory Cancellation Reason',
                hintText: 'e.g., Wrong item selected, customer return',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('DISMISS')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a cancellation reason.')),
                );
                return;
              }
              Navigator.pop(ctx); // Close alert
              Navigator.pop(context); // Close details sheet

              try {
                final salesRepo = ref.read(salesRepositoryProvider);
                await salesRepo.cancelSale(
                  saleId: widget.sale.id,
                  reason: reason,
                  fallbackAdminId: widget.currentProfile?.id,
                  fallbackAdminName: widget.currentProfile?.name,
                );

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Sale ${Formatters.formatSaleNumber(widget.sale.saleNumber)} cancelled & stock restored.'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Cancellation error: $e'), backgroundColor: AppColors.error),
                );
              }
            },
            child: const Text('CONFIRM CANCELLATION'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sale = widget.sale;
    final isAdmin = widget.currentProfile?.isAdmin == true;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transaction Receipt',
                style: GoogleFonts.outfit(fontSize: 19, fontWeight: FontWeight.w700),
              ),
              StatusBadge.saleStatus(sale.status),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariantLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildReceiptRow('Sale Number', Formatters.formatSaleNumber(sale.saleNumber)),
                const SizedBox(height: 4),
                _buildReceiptRow('Sold By', sale.sellerName ?? 'Seller'),
                const SizedBox(height: 4),
                _buildReceiptRow('Date & Time', Formatters.formatDateTime(sale.saleDate)),
                const SizedBox(height: 4),
                _buildReceiptRow('Payment Method', sale.paymentMethod.toUpperCase()),
                if (sale.isCancelled) ...[
                  const SizedBox(height: 4),
                  _buildReceiptRow('Cancelled By', sale.cancelledByName ?? 'Admin'),
                  const SizedBox(height: 4),
                  _buildReceiptRow('Reason', sale.cancellationReason ?? 'N/A'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Purchased Items',
            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: sale.items.length,
              separatorBuilder: (ctx, index) => const Divider(height: 1),
              itemBuilder: (ctx, idx) {
                final item = sale.items[idx];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productNameSnapshot,
                              style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            Text(
                              '${Formatters.formatQuantity(item.quantity, item.unitSnapshot)} × ${Formatters.currency(item.rateSnapshot)}',
                              style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondaryLight),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        Formatters.currency(item.amount),
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Paid', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700)),
              Text(
                Formatters.currency(sale.totalAmount),
                style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isAdmin && sale.isCompleted) ...[
            ElevatedButton.icon(
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('CANCEL SALE / RETURN STOCK'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _showCancelConfirmation,
            ),
          ],
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondaryLight)),
        Text(value, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight)),
      ],
    );
  }
}
