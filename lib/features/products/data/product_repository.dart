import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/supabase_service.dart';
import '../domain/category_model.dart';
import '../domain/product_model.dart';

class ProductRepository {
  final _uuid = const Uuid();

  // In-memory initial categories matching BPD
  static final List<CategoryModel> initialCategories = [
    CategoryModel(id: 'cat-rice', name: 'Rice & Cereals', displayOrder: 1, createdAt: DateTime(2026, 1, 1)),
    CategoryModel(id: 'cat-mercury', name: 'Mercury Naturals', displayOrder: 2, createdAt: DateTime(2026, 1, 1)),
    CategoryModel(id: 'sub-soaps', name: 'Soaps', parentId: 'cat-mercury', displayOrder: 1, createdAt: DateTime(2026, 1, 1)),
    CategoryModel(id: 'sub-haircare', name: 'Hair Care', parentId: 'cat-mercury', displayOrder: 2, createdAt: DateTime(2026, 1, 1)),
    CategoryModel(id: 'sub-cleaning', name: 'Cleaning Products', parentId: 'cat-mercury', displayOrder: 3, createdAt: DateTime(2026, 1, 1)),
  ];

  // In-memory initial products matching BPD
  static final List<ProductModel> initialProducts = [
    // Rice & Cereals
    ProductModel(id: 'prod-01', name: 'Thuyamali Rice', categoryId: 'cat-rice', brand: 'Traditional', unit: 'kg', sellingPrice: 120.0, costPrice: 95.0, currentStock: 200.0, minimumStock: 25.0, categoryName: 'Rice & Cereals', createdAt: DateTime(2026, 1, 1), updatedAt: DateTime(2026, 1, 1)),
    ProductModel(id: 'prod-02', name: 'Karuppukavani Rice', categoryId: 'cat-rice', brand: 'Traditional', unit: 'kg', sellingPrice: 180.0, costPrice: 140.0, currentStock: 100.0, minimumStock: 15.0, categoryName: 'Rice & Cereals', createdAt: DateTime(2026, 1, 1), updatedAt: DateTime(2026, 1, 1)),
    ProductModel(id: 'prod-03', name: 'Siraga Samba – Semi Polished', categoryId: 'cat-rice', brand: 'Traditional', unit: 'kg', sellingPrice: 160.0, costPrice: 125.0, currentStock: 150.0, minimumStock: 20.0, categoryName: 'Rice & Cereals', createdAt: DateTime(2026, 1, 1), updatedAt: DateTime(2026, 1, 1)),
    ProductModel(id: 'prod-04', name: 'Siraga Samba – Unpolished', categoryId: 'cat-rice', brand: 'Traditional', unit: 'kg', sellingPrice: 170.0, costPrice: 130.0, currentStock: 120.0, minimumStock: 20.0, categoryName: 'Rice & Cereals', createdAt: DateTime(2026, 1, 1), updatedAt: DateTime(2026, 1, 1)),
    ProductModel(id: 'prod-05', name: 'Mapillai Samba', categoryId: 'cat-rice', brand: 'Traditional', unit: 'kg', sellingPrice: 140.0, costPrice: 110.0, currentStock: 150.0, minimumStock: 20.0, categoryName: 'Rice & Cereals', createdAt: DateTime(2026, 1, 1), updatedAt: DateTime(2026, 1, 1)),
    ProductModel(id: 'prod-06', name: 'Karunguruvai Rice', categoryId: 'cat-rice', brand: 'Traditional', unit: 'kg', sellingPrice: 150.0, costPrice: 115.0, currentStock: 100.0, minimumStock: 15.0, categoryName: 'Rice & Cereals', createdAt: DateTime(2026, 1, 1), updatedAt: DateTime(2026, 1, 1)),
    ProductModel(id: 'prod-07', name: 'Angur Sanna', categoryId: 'cat-rice', brand: 'Traditional', unit: 'kg', sellingPrice: 110.0, costPrice: 85.0, currentStock: 100.0, minimumStock: 15.0, categoryName: 'Rice & Cereals', createdAt: DateTime(2026, 1, 1), updatedAt: DateTime(2026, 1, 1)),
    ProductModel(id: 'prod-08', name: 'Mysore Malli Rice', categoryId: 'cat-rice', brand: 'Traditional', unit: 'kg', sellingPrice: 130.0, costPrice: 100.0, currentStock: 100.0, minimumStock: 15.0, categoryName: 'Rice & Cereals', createdAt: DateTime(2026, 1, 1), updatedAt: DateTime(2026, 1, 1)),
    ProductModel(id: 'prod-09', name: 'Thuvaram Paruppu', categoryId: 'cat-rice', brand: 'Traditional', unit: 'kg', sellingPrice: 190.0, costPrice: 155.0, currentStock: 80.0, minimumStock: 10.0, categoryName: 'Rice & Cereals', createdAt: DateTime(2026, 1, 1), updatedAt: DateTime(2026, 1, 1)),

    // Soaps
    ProductModel(id: 'prod-10', name: 'Vetiver Soap', categoryId: 'cat-mercury', subcategoryId: 'sub-soaps', brand: 'Mercury Naturals', unit: 'piece', sellingPrice: 80.0, costPrice: 55.0, currentStock: 100.0, minimumStock: 10.0, categoryName: 'Mercury Naturals', subcategoryName: 'Soaps', createdAt: DateTime(2026, 1, 1), updatedAt: DateTime(2026, 1, 1)),
    ProductModel(id: 'prod-11', name: 'Charcoal Soap', categoryId: 'cat-mercury', subcategoryId: 'sub-soaps', brand: 'Mercury Naturals', unit: 'piece', sellingPrice: 80.0, costPrice: 55.0, currentStock: 75.0, minimumStock: 10.0, categoryName: 'Mercury Naturals', subcategoryName: 'Soaps', createdAt: DateTime(2026, 1, 1), updatedAt: DateTime(2026, 1, 1)),
    ProductModel(id: 'prod-12', name: 'Veepilai Manjal Soap', categoryId: 'cat-mercury', subcategoryId: 'sub-soaps', brand: 'Mercury Naturals', unit: 'piece', sellingPrice: 80.0, costPrice: 55.0, currentStock: 60.0, minimumStock: 10.0, categoryName: 'Mercury Naturals', subcategoryName: 'Soaps', createdAt: DateTime(2026, 1, 1), updatedAt: DateTime(2026, 1, 1)),
    ProductModel(id: 'prod-13', name: 'Kasthuri Manjal Soap', categoryId: 'cat-mercury', subcategoryId: 'sub-soaps', brand: 'Mercury Naturals', unit: 'piece', sellingPrice: 80.0, costPrice: 55.0, currentStock: 60.0, minimumStock: 10.0, categoryName: 'Mercury Naturals', subcategoryName: 'Soaps', createdAt: DateTime(2026, 1, 1), updatedAt: DateTime(2026, 1, 1)),
    ProductModel(id: 'prod-14', name: 'Multani Mitti Soap', categoryId: 'cat-mercury', subcategoryId: 'sub-soaps', brand: 'Mercury Naturals', unit: 'piece', sellingPrice: 80.0, costPrice: 55.0, currentStock: 50.0, minimumStock: 10.0, categoryName: 'Mercury Naturals', subcategoryName: 'Soaps', createdAt: DateTime(2026, 1, 1), updatedAt: DateTime(2026, 1, 1)),
    ProductModel(id: 'prod-15', name: 'Kuppaimeni Soap', categoryId: 'cat-mercury', subcategoryId: 'sub-soaps', brand: 'Mercury Naturals', unit: 'piece', sellingPrice: 80.0, costPrice: 55.0, currentStock: 70.0, minimumStock: 10.0, categoryName: 'Mercury Naturals', subcategoryName: 'Soaps', createdAt: DateTime(2026, 1, 1), updatedAt: DateTime(2026, 1, 1)),
    ProductModel(id: 'prod-16', name: 'Aloevera Soap', categoryId: 'cat-mercury', subcategoryId: 'sub-soaps', brand: 'Mercury Naturals', unit: 'piece', sellingPrice: 80.0, costPrice: 55.0, currentStock: 80.0, minimumStock: 10.0, categoryName: 'Mercury Naturals', subcategoryName: 'Soaps', createdAt: DateTime(2026, 1, 1), updatedAt: DateTime(2026, 1, 1)),
    ProductModel(id: 'prod-17', name: 'Red Wine Soap', categoryId: 'cat-mercury', subcategoryId: 'sub-soaps', brand: 'Mercury Naturals', unit: 'piece', sellingPrice: 95.0, costPrice: 65.0, currentStock: 40.0, minimumStock: 10.0, categoryName: 'Mercury Naturals', subcategoryName: 'Soaps', createdAt: DateTime(2026, 1, 1), updatedAt: DateTime(2026, 1, 1)),
    ProductModel(id: 'prod-18', name: 'Sandal Soap', categoryId: 'cat-mercury', subcategoryId: 'sub-soaps', brand: 'Mercury Naturals', unit: 'piece', sellingPrice: 85.0, costPrice: 60.0, currentStock: 90.0, minimumStock: 10.0, categoryName: 'Mercury Naturals', subcategoryName: 'Soaps', createdAt: DateTime(2026, 1, 1), updatedAt: DateTime(2026, 1, 1)),
    ProductModel(id: 'prod-19', name: 'Goat Milk Soap', categoryId: 'cat-mercury', subcategoryId: 'sub-soaps', brand: 'Mercury Naturals', unit: 'piece', sellingPrice: 90.0, costPrice: 60.0, currentStock: 50.0, minimumStock: 10.0, categoryName: 'Mercury Naturals', subcategoryName: 'Soaps', createdAt: DateTime(2026, 1, 1), updatedAt: DateTime(2026, 1, 1)),

    // Hair Care
    ProductModel(id: 'prod-20', name: 'Mulugi Hair Oil', categoryId: 'cat-mercury', subcategoryId: 'sub-haircare', brand: 'Mercury Naturals', unit: 'bottle', sellingPrice: 180.0, costPrice: 130.0, currentStock: 40.0, minimumStock: 8.0, categoryName: 'Mercury Naturals', subcategoryName: 'Hair Care', createdAt: DateTime(2026, 1, 1), updatedAt: DateTime(2026, 1, 1)),
    ProductModel(id: 'prod-21', name: 'Karum Siraga Hair Oil', categoryId: 'cat-mercury', subcategoryId: 'sub-haircare', brand: 'Mercury Naturals', unit: 'bottle', sellingPrice: 190.0, costPrice: 135.0, currentStock: 35.0, minimumStock: 8.0, categoryName: 'Mercury Naturals', subcategoryName: 'Hair Care', createdAt: DateTime(2026, 1, 1), updatedAt: DateTime(2026, 1, 1)),
    ProductModel(id: 'prod-22', name: 'Hair Dye', categoryId: 'cat-mercury', subcategoryId: 'sub-haircare', brand: 'Mercury Naturals', unit: 'packet', sellingPrice: 120.0, costPrice: 85.0, currentStock: 50.0, minimumStock: 10.0, categoryName: 'Mercury Naturals', subcategoryName: 'Hair Care', createdAt: DateTime(2026, 1, 1), updatedAt: DateTime(2026, 1, 1)),
    ProductModel(id: 'prod-23', name: 'Sembaruthi Shampoo', categoryId: 'cat-mercury', subcategoryId: 'sub-haircare', brand: 'Mercury Naturals', unit: 'bottle', sellingPrice: 150.0, costPrice: 105.0, currentStock: 50.0, minimumStock: 10.0, categoryName: 'Mercury Naturals', subcategoryName: 'Hair Care', createdAt: DateTime(2026, 1, 1), updatedAt: DateTime(2026, 1, 1)),
    ProductModel(id: 'prod-24', name: 'Aloevera Shampoo', categoryId: 'cat-mercury', subcategoryId: 'sub-haircare', brand: 'Mercury Naturals', unit: 'bottle', sellingPrice: 150.0, costPrice: 105.0, currentStock: 45.0, minimumStock: 10.0, categoryName: 'Mercury Naturals', subcategoryName: 'Hair Care', createdAt: DateTime(2026, 1, 1), updatedAt: DateTime(2026, 1, 1)),
    ProductModel(id: 'prod-25', name: 'Karusilakanni Shampoo', categoryId: 'cat-mercury', subcategoryId: 'sub-haircare', brand: 'Mercury Naturals', unit: 'bottle', sellingPrice: 160.0, costPrice: 110.0, currentStock: 40.0, minimumStock: 10.0, categoryName: 'Mercury Naturals', subcategoryName: 'Hair Care', createdAt: DateTime(2026, 1, 1), updatedAt: DateTime(2026, 1, 1)),
    ProductModel(id: 'prod-26', name: 'Sikakai Shampoo', categoryId: 'cat-mercury', subcategoryId: 'sub-haircare', brand: 'Mercury Naturals', unit: 'bottle', sellingPrice: 150.0, costPrice: 105.0, currentStock: 50.0, minimumStock: 10.0, categoryName: 'Mercury Naturals', subcategoryName: 'Hair Care', createdAt: DateTime(2026, 1, 1), updatedAt: DateTime(2026, 1, 1)),

    // Cleaning Products
    ProductModel(id: 'prod-27', name: 'Dishwashing Liquid', categoryId: 'cat-mercury', subcategoryId: 'sub-cleaning', brand: 'Mercury Naturals', unit: 'bottle', sellingPrice: 90.0, costPrice: 60.0, currentStock: 60.0, minimumStock: 12.0, categoryName: 'Mercury Naturals', subcategoryName: 'Cleaning Products', createdAt: DateTime(2026, 1, 1), updatedAt: DateTime(2026, 1, 1)),
    ProductModel(id: 'prod-28', name: 'Cloth Washing Liquid', categoryId: 'cat-mercury', subcategoryId: 'sub-cleaning', brand: 'Mercury Naturals', unit: 'bottle', sellingPrice: 110.0, costPrice: 75.0, currentStock: 50.0, minimumStock: 12.0, categoryName: 'Mercury Naturals', subcategoryName: 'Cleaning Products', createdAt: DateTime(2026, 1, 1), updatedAt: DateTime(2026, 1, 1)),
  ];

  final List<ProductModel> _products = List.from(initialProducts);
  final List<CategoryModel> _categories = List.from(initialCategories);

  final _productsController = StreamController<List<ProductModel>>.broadcast();
  final _categoriesController = StreamController<List<CategoryModel>>.broadcast();

  ProductRepository() {
    _initSupabaseSync();
  }

  void _initSupabaseSync() {
    final client = SupabaseService.client;
    if (client != null) {
      // Listen to Realtime updates on products table
      client
          .channel('public:products')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'products',
            callback: (payload) {
              refreshProducts();
            },
          )
          .subscribe();

      // Listen to Realtime updates on categories table
      client
          .channel('public:categories')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'categories',
            callback: (payload) {
              refreshCategories();
            },
          )
          .subscribe();
    }
  }

  Stream<List<ProductModel>> get productsStream {
    // Emit current list first
    Timer.run(() => _productsController.add(List.unmodifiable(_products)));
    return _productsController.stream;
  }

  Stream<List<CategoryModel>> get categoriesStream {
    Timer.run(() => _categoriesController.add(List.unmodifiable(_categories)));
    return _categoriesController.stream;
  }

  Future<List<ProductModel>> getProducts() async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        final res = await client
            .from('products')
            .select('*, categories:category_id(name), subcategories:subcategory_id(name)')
            .order('name');
        final fetched = (res as List).map((e) => ProductModel.fromJson(e)).toList();
        _products.clear();
        _products.addAll(fetched);
        _productsController.add(List.unmodifiable(_products));
        return _products;
      } catch (e) {
        debugPrint('Error fetching products from Supabase: $e');
      }
    }
    return List.unmodifiable(_products);
  }

  Future<List<CategoryModel>> getCategories() async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        final res = await client.from('categories').select().order('display_order');
        final fetched = (res as List).map((e) => CategoryModel.fromJson(e)).toList();
        _categories.clear();
        _categories.addAll(fetched);
        _categoriesController.add(List.unmodifiable(_categories));
        return _categories;
      } catch (e) {
        debugPrint('Error fetching categories from Supabase: $e');
      }
    }
    return List.unmodifiable(_categories);
  }

  Future<void> refreshProducts() async {
    await getProducts();
  }

  Future<void> refreshCategories() async {
    await getCategories();
  }

  Future<ProductModel> addProduct(ProductModel product) async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        final res = await client
            .from('products')
            .insert(product.toJson())
            .select('*, categories:category_id(name), subcategories:subcategory_id(name)')
            .single();
        final created = ProductModel.fromJson(res);
        _products.add(created);
        _productsController.add(List.unmodifiable(_products));
        return created;
      } catch (e) {
        debugPrint('Supabase insert error: $e');
      }
    }

    final localProduct = product.copyWith(
      id: 'prod-${_uuid.v4().substring(0, 8)}',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _products.add(localProduct);
    _productsController.add(List.unmodifiable(_products));
    return localProduct;
  }

  Future<ProductModel> updateProduct(ProductModel product) async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        final res = await client
            .from('products')
            .update(product.toJson())
            .eq('id', product.id)
            .select('*, categories:category_id(name), subcategories:subcategory_id(name)')
            .single();
        final updated = ProductModel.fromJson(res);
        final index = _products.indexWhere((p) => p.id == product.id);
        if (index != -1) {
          _products[index] = updated;
          _productsController.add(List.unmodifiable(_products));
        }
        return updated;
      } catch (e) {
        debugPrint('Supabase update product error: $e');
      }
    }

    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      final updated = product.copyWith(updatedAt: DateTime.now());
      _products[index] = updated;
      _productsController.add(List.unmodifiable(_products));
      return updated;
    }
    return product;
  }

  Future<void> updateStockDirectly(String productId, double delta) async {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final current = _products[index];
      final newStock = current.currentStock + delta;
      _products[index] = current.copyWith(currentStock: newStock >= 0 ? newStock : 0);
      _productsController.add(List.unmodifiable(_products));
    }
  }

  Future<CategoryModel> addCategory(String name, {String? parentId}) async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        final res = await client
            .from('categories')
            .insert({'name': name, 'parent_id': parentId})
            .select()
            .single();
        final cat = CategoryModel.fromJson(res);
        _categories.add(cat);
        _categoriesController.add(List.unmodifiable(_categories));
        return cat;
      } catch (e) {
        debugPrint('Supabase add category error: $e');
      }
    }

    final cat = CategoryModel(
      id: 'cat-${_uuid.v4().substring(0, 8)}',
      name: name,
      parentId: parentId,
      createdAt: DateTime.now(),
    );
    _categories.add(cat);
    _categoriesController.add(List.unmodifiable(_categories));
    return cat;
  }
}
