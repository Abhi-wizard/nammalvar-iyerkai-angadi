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
import '../domain/cart_item_model.dart';
import 'cart_provider.dart';
import 'sales_providers.dart';

class NewSaleScreen extends ConsumerStatefulWidget {
  const NewSaleScreen({super.key});

  @override
  ConsumerState<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends ConsumerState<NewSaleScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentProfile = ref.watch(currentProfileProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final selectedCat = ref.watch(selectedCategoryFilterProvider);
    final filteredProducts = ref.watch(filteredProductsProvider);
    final cartItems = ref.watch(cartProvider);
    final cartTotal = ref.watch(cartProvider.notifier).totalAmount;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'New Sale / POS',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 19),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'Seller: ${currentProfile?.name ?? "Unknown"}',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (cartItems.isNotEmpty)
            IconButton(
              tooltip: 'Clear Cart',
              icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.error),
              onPressed: () {
                ref.read(cartProvider.notifier).clearCart();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => ref.read(productSearchQueryProvider.notifier).state = val,
              decoration: InputDecoration(
                hintText: 'Search products, soap, rice, oil...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(productSearchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceLight,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // 2. Category Filter Chips
          categoriesAsync.maybeWhen(
            data: (categories) {
              return SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('All Products'),
                        selected: selectedCat == null,
                        onSelected: (_) => ref.read(selectedCategoryFilterProvider.notifier).state = null,
                        selectedColor: AppColors.primaryContainer,
                        checkmarkColor: AppColors.primary,
                      ),
                    ),
                    ...categories.map((cat) {
                      final isSelected = selectedCat == cat.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(cat.name),
                          selected: isSelected,
                          onSelected: (_) {
                            ref.read(selectedCategoryFilterProvider.notifier).state =
                                isSelected ? null : cat.id;
                          },
                          selectedColor: AppColors.primaryContainer,
                          checkmarkColor: AppColors.primary,
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),

          const SizedBox(height: 8),

          // 3. Product Catalog Grid / List
          Expanded(
            child: filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textSecondaryLight.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        Text(
                          'No products found',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            color: AppColors.textSecondaryLight,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      final cartItem = cartItems.cast<CartItemModel?>().firstWhere(
                            (c) => c?.product.id == product.id,
                            orElse: () => null,
                          );

                      return _buildProductListItem(context, product, cartItem);
                    },
                  ),
          ),
        ],
      ),
      bottomSheet: cartItems.isNotEmpty
          ? _buildCartFloatingSheet(context, cartItems, cartTotal, currentProfile)
          : null,
    );
  }

  Widget _buildProductListItem(
    BuildContext context,
    ProductModel product,
    CartItemModel? cartItem,
  ) {
    final inCart = cartItem != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        color: inCart ? AppColors.primaryContainer.withValues(alpha: 0.25) : AppColors.surfaceLight,
        border: inCart ? const BorderSide(color: AppColors.primary, width: 1.5) : null,
        child: Row(
          children: [
            // Left icon / category tag
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: inCart ? AppColors.primary : AppColors.surfaceVariantLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  product.unit == 'kg' ? Icons.grain : (product.unit == 'bottle' ? Icons.water_drop_outlined : Icons.spa_outlined),
                  color: inCart ? Colors.white : AppColors.primary,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Middle Product Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${Formatters.currency(product.sellingPrice)} / ${product.unit}',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        StatusBadge.stock(
                          stock: product.currentStock,
                          minStock: product.minimumStock,
                          unit: product.unit,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Right Action: Add button or Quantity stepper
            if (inCart) ...[
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () {
                        final step = (product.unit == 'kg' || product.unit == 'litre') ? 0.5 : 1.0;
                        ref.read(cartProvider.notifier).updateQuantity(
                              product.id,
                              cartItem.quantity - step,
                            );
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        child: Icon(Icons.remove, size: 18, color: AppColors.primary),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showQuantityDialog(context, product, cartItem.quantity),
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 26),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        color: AppColors.primaryContainer.withValues(alpha: 0.4),
                        child: Text(
                          Formatters.formatQuantity(cartItem.quantity, ''),
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        final step = (product.unit == 'kg' || product.unit == 'litre') ? 0.5 : 1.0;
                        if (cartItem.quantity + step > product.currentStock) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Cannot exceed available stock of ${product.currentStock} ${product.unit}'),
                              backgroundColor: AppColors.warning,
                            ),
                          );
                          return;
                        }
                        ref.read(cartProvider.notifier).updateQuantity(
                              product.id,
                              cartItem.quantity + step,
                            );
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        child: Icon(Icons.add, size: 18, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: product.currentStock <= 0
                    ? null
                    : () {
                        final defaultQty = (product.unit == 'kg' || product.unit == 'litre') ? 1.0 : 1.0;
                        ref.read(cartProvider.notifier).addProduct(product, quantity: defaultQty);
                      },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(64, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  backgroundColor: AppColors.primary,
                ),
                child: Text(
                  product.currentStock <= 0 ? 'Out' : 'ADD',
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showQuantityDialog(BuildContext context, ProductModel product, double initialQty) {
    final controller = TextEditingController(text: initialQty.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Quantity for ${product.name}', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 17)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Enter Quantity (${product.unit})',
                suffixText: product.unit,
              ),
            ),
            const SizedBox(height: 12),
            // Quick preset chips
            Wrap(
              spacing: 8,
              children: [0.5, 1.0, 2.0, 2.5, 5.0].map((val) {
                return ActionChip(
                  label: Text('$val ${product.unit}'),
                  onPressed: () {
                    controller.text = val.toString();
                  },
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text.trim());
              if (val != null && val > 0) {
                if (val > product.currentStock) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Cannot exceed stock of ${product.currentStock} ${product.unit}'),
                      backgroundColor: AppColors.warning,
                    ),
                  );
                } else {
                  ref.read(cartProvider.notifier).updateQuantity(product.id, val);
                  Navigator.pop(ctx);
                }
              }
            },
            child: const Text('SET QUANTITY'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartFloatingSheet(
    BuildContext context,
    List<CartItemModel> cartItems,
    double cartTotal,
    dynamic currentProfile,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${cartItems.length} ITEMS',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                Text(
                  Formatters.currency(cartTotal),
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.shopping_cart_checkout),
                label: const Text('CHECKOUT'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => _showCheckoutModal(context, cartItems, cartTotal, currentProfile),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCheckoutModal(
    BuildContext context,
    List<CartItemModel> cartItems,
    double cartTotal,
    dynamic currentProfile,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CheckoutModalSheet(
        cartItems: cartItems,
        cartTotal: cartTotal,
        sellerId: currentProfile?.id ?? '00000000-0000-0000-0000-000000000002',
        sellerName: currentProfile?.name ?? 'Seller',
      ),
    );
  }
}

class _CheckoutModalSheet extends ConsumerStatefulWidget {
  final List<CartItemModel> cartItems;
  final double cartTotal;
  final String sellerId;
  final String sellerName;

  const _CheckoutModalSheet({
    required this.cartItems,
    required this.cartTotal,
    required this.sellerId,
    required this.sellerName,
  });

  @override
  ConsumerState<_CheckoutModalSheet> createState() => _CheckoutModalSheetState();
}

class _CheckoutModalSheetState extends ConsumerState<_CheckoutModalSheet> {
  String _selectedPayment = 'cash';
  bool _isProcessing = false;

  Future<void> _handleSaveSale() async {
    setState(() => _isProcessing = true);
    try {
      final salesRepo = ref.read(salesRepositoryProvider);
      final sale = await salesRepo.processSale(
        paymentMethod: _selectedPayment,
        cartItems: widget.cartItems,
        fallbackSellerId: widget.sellerId,
        fallbackSellerName: widget.sellerName,
      );

      ref.read(cartProvider.notifier).clearCart();
      if (!mounted) return;
      Navigator.pop(context); // Close sheet

      // Show success receipt dialog
      _showSaleSuccessDialog(sale);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sale error: $e'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSaleSuccessDialog(dynamic sale) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: AppColors.success, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              'Sale Successful!',
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Sale ${Formatters.formatSaleNumber(sale.saleNumber)}',
              style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariantLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Amount:', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                  Text(
                    Formatters.currency(sale.totalAmount),
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Recorded by: ${sale.sellerName}\nPayment: ${sale.paymentMethod.toUpperCase()}',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondaryLight),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('DONE / NEXT SALE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                'Review & Checkout',
                style: GoogleFonts.outfit(fontSize: 19, fontWeight: FontWeight.w700),
              ),
              Text(
                'Sold by: ${widget.sellerName}',
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),

          // Cart Items List
          Expanded(
            child: ListView.separated(
              itemCount: widget.cartItems.length,
              separatorBuilder: (ctx, index) => const Divider(height: 1),
              itemBuilder: (ctx, idx) {
                final item = widget.cartItems[idx];
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
                              item.product.name,
                              style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            Text(
                              '${Formatters.formatQuantity(item.quantity, item.product.unit)} × ${Formatters.currency(item.customRate)}',
                              style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondaryLight),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        Formatters.currency(item.amount),
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const Divider(),
          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Amount', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
              Text(
                Formatters.currency(widget.cartTotal),
                style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Payment Method Selector
          Text('Select Payment Method', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildPaymentOption('cash', 'CASH', Icons.payments_outlined, AppColors.chipCash),
              const SizedBox(width: 8),
              _buildPaymentOption('upi', 'UPI', Icons.qr_code, AppColors.chipUpi),
              const SizedBox(width: 8),
              _buildPaymentOption('other', 'OTHER', Icons.credit_card, AppColors.chipOther),
            ],
          ),

          const SizedBox(height: 20),

          // SAVE SALE Button
          ElevatedButton(
            onPressed: _isProcessing ? null : _handleSaveSale,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.primary,
            ),
            child: _isProcessing
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('SAVE SALE (${Formatters.currency(widget.cartTotal)})', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String key, String label, IconData icon, Color color) {
    final isSelected = _selectedPayment == key;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _selectedPayment = key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : AppColors.surfaceVariantLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : AppColors.textSecondaryLight, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? color : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
