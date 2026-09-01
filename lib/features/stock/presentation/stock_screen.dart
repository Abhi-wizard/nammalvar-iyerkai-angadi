import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../products/domain/product_model.dart';
import '../../products/presentation/product_providers.dart';
import '../domain/stock_movement_model.dart';
import 'stock_providers.dart';

class StockScreen extends ConsumerStatefulWidget {
  const StockScreen({super.key});

  @override
  ConsumerState<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends ConsumerState<StockScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentProfile = ref.watch(currentProfileProvider);
    final products = ref.watch(filteredProductsProvider);
    final lowStockProducts = ref.watch(lowStockProductsProvider);
    final movements = ref.watch(filteredStockMovementsProvider);
    final isAdmin = currentProfile?.isAdmin == true;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Stock & Inventory',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondaryLight,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Current Stock'),
                  if (lowStockProducts.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                      child: Text(
                        lowStockProducts.length.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Movement Ledger'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Current Stock Tab
          _buildCurrentStockTab(context, products, isAdmin),

          // 2. Movement Ledger Tab
          _buildMovementLedgerTab(context, movements),
        ],
      ),
    );
  }

  Widget _buildCurrentStockTab(BuildContext context, List<ProductModel> products, bool isAdmin) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          StatusBadge.stock(
                            stock: product.currentStock,
                            minStock: product.minimumStock,
                            unit: product.unit,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Min: ${product.minimumStock} ${product.unit}',
                            style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondaryLight),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isAdmin) ...[
                  IconButton(
                    tooltip: 'Receive Stock',
                    icon: const Icon(Icons.add_shopping_cart, color: AppColors.primary),
                    onPressed: () => _showReceiveStockModal(context, product),
                  ),
                  IconButton(
                    tooltip: 'Adjust Stock',
                    icon: const Icon(Icons.tune, color: AppColors.warning),
                    onPressed: () => _showAdjustStockModal(context, product),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMovementLedgerTab(BuildContext context, List<StockMovementModel> movements) {
    if (movements.isEmpty) {
      return Center(
        child: Text('No stock movements recorded', style: GoogleFonts.outfit(color: AppColors.textSecondaryLight)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: movements.length,
      itemBuilder: (context, index) {
        final mov = movements[index];
        final isPositive = mov.quantity > 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isPositive ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      isPositive ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isPositive ? AppColors.success : AppColors.error,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mov.productName ?? 'Product',
                        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${mov.reason ?? mov.movementType.toUpperCase()} • ${mov.performedByName ?? "User"}',
                        style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondaryLight),
                      ),
                      Text(
                        Formatters.formatDateTime(mov.createdAt),
                        style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isPositive ? "+" : ""}${Formatters.formatQuantity(mov.quantity, mov.unit ?? "")}',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isPositive ? AppColors.success : AppColors.error,
                      ),
                    ),
                    Text(
                      'Bal: ${Formatters.formatQuantity(mov.balanceAfter, mov.unit ?? "")}',
                      style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showReceiveStockModal(BuildContext context, ProductModel product) {
    final qtyController = TextEditingController();
    final costController = TextEditingController(text: product.costPrice.toString());
    final invoiceController = TextEditingController();
    final currentProfile = ref.read(currentProfileProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: const BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Receive Inward Stock: ${product.name}', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              TextField(
                controller: qtyController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Received Quantity (${product.unit}) *',
                  suffixText: product.unit,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: costController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Cost Price per unit (₹)',
                  prefixText: '₹ ',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: invoiceController,
                decoration: const InputDecoration(
                  labelText: 'Supplier / Invoice Number (Optional)',
                  hintText: 'e.g., ABC Supplier #4582',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final qty = double.tryParse(qtyController.text.trim());
                  final cost = double.tryParse(costController.text.trim()) ?? product.costPrice;
                  if (qty != null && qty > 0) {
                    Navigator.pop(ctx);
                    final stockRepo = ref.read(stockRepositoryProvider);
                    await stockRepo.receiveStock(
                      productId: product.id,
                      productName: product.name,
                      unit: product.unit,
                      quantity: qty,
                      costPrice: cost,
                      invoiceNumber: invoiceController.text.trim(),
                      fallbackUserId: currentProfile?.id,
                      fallbackUserName: currentProfile?.name,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Received $qty ${product.unit} of ${product.name} into stock.'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  }
                },
                child: const Text('SAVE INWARD STOCK'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAdjustStockModal(BuildContext context, ProductModel product) {
    final deltaController = TextEditingController();
    final reasonController = TextEditingController();
    final currentProfile = ref.read(currentProfileProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: const BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Adjust Physical Stock: ${product.name}', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700)),
              Text('Current: ${product.currentStock} ${product.unit}', style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondaryLight)),
              const SizedBox(height: 14),
              TextField(
                controller: deltaController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Stock Delta (+/- in ${product.unit}) *',
                  hintText: 'e.g., -2 or +5',
                  suffixText: product.unit,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Mandatory Adjustment Reason *',
                  hintText: 'e.g., Physical count correction, Spillage',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final delta = double.tryParse(deltaController.text.trim());
                  final reason = reasonController.text.trim();
                  if (delta == null || delta == 0) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid delta.')));
                    return;
                  }
                  if (reason.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a mandatory reason.')));
                    return;
                  }
                  Navigator.pop(ctx);
                  final stockRepo = ref.read(stockRepositoryProvider);
                  await stockRepo.adjustStock(
                    productId: product.id,
                    productName: product.name,
                    unit: product.unit,
                    adjustmentDelta: delta,
                    reason: reason,
                    fallbackUserId: currentProfile?.id,
                    fallbackUserName: currentProfile?.name,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Stock adjusted for ${product.name}.'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
                child: const Text('APPLY ADJUSTMENT'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
