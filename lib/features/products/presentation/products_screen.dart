import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/seller_switcher_modal.dart';
import '../../auth/presentation/auth_providers.dart';
import '../domain/product_model.dart';
import 'product_providers.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
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
    final products = ref.watch(filteredProductsProvider);
    final isAdmin = currentProfile?.isAdmin == true;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Products Catalog',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Switch User',
            icon: const Icon(Icons.switch_account_outlined, color: AppColors.primary),
            onPressed: () => SellerSwitcherModal.show(context),
          ),
          if (isAdmin)
            IconButton(
              tooltip: 'Add Product',
              icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 28),
              onPressed: () => _showAddEditProductModal(context, null),
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
                hintText: 'Search products by name or category...',
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
                    FilterChip(
                      label: const Text('All Categories'),
                      selected: selectedCat == null,
                      onSelected: (_) => ref.read(selectedCategoryFilterProvider.notifier).state = null,
                    ),
                    const SizedBox(width: 8),
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

          // 3. Products List
          Expanded(
            child: products.isEmpty
                ? Center(
                    child: Text(
                      'No products in catalog',
                      style: GoogleFonts.outfit(color: AppColors.textSecondaryLight),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return _buildProductCard(context, product, isAdmin);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text('ADD PRODUCT', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.white)),
              onPressed: () => _showAddEditProductModal(context, null),
            )
          : null,
    );
  }

  Widget _buildProductCard(BuildContext context, ProductModel product, bool isAdmin) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: isAdmin ? () => _showAddEditProductModal(context, product) : null,
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariantLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  product.unit == 'kg' ? Icons.grain : (product.unit == 'bottle' ? Icons.water_drop_outlined : Icons.spa_outlined),
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${Formatters.currency(product.sellingPrice)} / ${product.unit}',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      if (isAdmin && product.costPrice > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          '(Cost: ${Formatters.currency(product.costPrice)})',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusBadge.stock(
                  stock: product.currentStock,
                  minStock: product.minimumStock,
                  unit: product.unit,
                ),
                if (isAdmin) ...[
                  const SizedBox(height: 4),
                  const Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondaryLight),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEditProductModal(BuildContext context, ProductModel? product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddEditProductModalSheet(product: product),
    );
  }
}

class _AddEditProductModalSheet extends ConsumerStatefulWidget {
  final ProductModel? product;

  const _AddEditProductModalSheet({this.product});

  @override
  ConsumerState<_AddEditProductModalSheet> createState() => _AddEditProductModalSheetState();
}

class _AddEditProductModalSheetState extends ConsumerState<_AddEditProductModalSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _costPriceController;
  late TextEditingController _minStockController;
  late TextEditingController _currentStockController;
  String _selectedUnit = 'piece';
  String? _selectedCategory;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _brandController = TextEditingController(text: p?.brand ?? '');
    _sellingPriceController = TextEditingController(text: p != null ? p.sellingPrice.toString() : '');
    _costPriceController = TextEditingController(text: p != null ? p.costPrice.toString() : '0');
    _minStockController = TextEditingController(text: p != null ? p.minimumStock.toString() : '5');
    _currentStockController = TextEditingController(text: p != null ? p.currentStock.toString() : '0');
    _selectedUnit = p?.unit ?? 'piece';
    _selectedCategory = p?.categoryId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _sellingPriceController.dispose();
    _costPriceController.dispose();
    _minStockController.dispose();
    _currentStockController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(productRepositoryProvider);
      final isEditing = widget.product != null;

      final updated = ProductModel(
        id: widget.product?.id ?? '',
        name: _nameController.text.trim(),
        categoryId: _selectedCategory!,
        brand: _brandController.text.trim().isNotEmpty ? _brandController.text.trim() : null,
        unit: _selectedUnit,
        sellingPrice: double.parse(_sellingPriceController.text.trim()),
        costPrice: double.tryParse(_costPriceController.text.trim()) ?? 0.0,
        currentStock: double.tryParse(_currentStockController.text.trim()) ?? 0.0,
        minimumStock: double.tryParse(_minStockController.text.trim()) ?? 5.0,
        createdAt: widget.product?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (isEditing) {
        await repo.updateProduct(updated);
      } else {
        await repo.addProduct(updated);
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Product updated.' : 'Product added to catalog.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final isEditing = widget.product != null;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
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
            Text(
              isEditing ? 'Edit Product' : 'Add New Product',
              style: GoogleFonts.outfit(fontSize: 19, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Product Name *'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter product name' : null,
                  ),
                  const SizedBox(height: 12),
                  // Category selector
                  categoriesAsync.maybeWhen(
                    data: (cats) {
                      if (_selectedCategory == null && cats.isNotEmpty) {
                        _selectedCategory = cats.first.id;
                      }
                      return DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        decoration: const InputDecoration(labelText: 'Category *'),
                        items: cats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                        onChanged: (val) => setState(() => _selectedCategory = val),
                      );
                    },
                    orElse: () => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 12),
                  // Unit selector
                  DropdownButtonFormField<String>(
                    initialValue: _selectedUnit,
                    decoration: const InputDecoration(labelText: 'Unit *'),
                    items: AppConstants.units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedUnit = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _sellingPriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Selling Price (₹) *',
                            prefixText: '₹ ',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Enter price';
                            if (double.tryParse(v) == null) return 'Invalid';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _costPriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Cost Price (₹)',
                            prefixText: '₹ ',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _currentStockController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: isEditing ? 'Current Stock' : 'Opening Stock',
                            suffixText: _selectedUnit,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _minStockController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Minimum Stock Alert',
                            suffixText: _selectedUnit,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _brandController,
                    decoration: const InputDecoration(labelText: 'Brand / Farm (Optional)'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _isSaving ? null : _handleSave,
              child: _isSaving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                  : Text(isEditing ? 'UPDATE PRODUCT' : 'SAVE PRODUCT'),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
