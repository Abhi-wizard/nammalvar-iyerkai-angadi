import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/supabase_service.dart';
import '../domain/category_model.dart';
import '../domain/product_model.dart';

class ProductRepository {
  final _uuid = const Uuid();

  // Test fallback categories for offline unit tests
  static final List<CategoryModel> testFallbackCategories = [
    CategoryModel(id: '00000000-0000-0000-0001-000000000001', name: 'Rice & Cereals', displayOrder: 1, createdAt: DateTime(2026, 1, 1)),
    CategoryModel(id: '00000000-0000-0000-0001-000000000002', name: 'Mercury Naturals', displayOrder: 2, createdAt: DateTime(2026, 1, 1)),
  ];

  // Test fallback products with valid UUIDs for offline unit tests
  static final List<ProductModel> testFallbackProducts = [
    ProductModel(
      id: '00000000-0000-0000-0002-000000000001',
      name: 'Thuyamali Rice',
      categoryId: '00000000-0000-0000-0001-000000000001',
      brand: 'Traditional',
      unit: 'kg',
      sellingPrice: 120.0,
      costPrice: 95.0,
      currentStock: 200.0,
      minimumStock: 25.0,
      categoryName: 'Rice & Cereals',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
    ProductModel(
      id: '00000000-0000-0000-0002-000000000010',
      name: 'Vetiver Soap',
      categoryId: '00000000-0000-0000-0001-000000000002',
      brand: 'Mercury Naturals',
      unit: 'piece',
      sellingPrice: 80.0,
      costPrice: 55.0,
      currentStock: 100.0,
      minimumStock: 10.0,
      categoryName: 'Mercury Naturals',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
  ];

  final List<ProductModel> _products = [];
  final List<CategoryModel> _categories = [];

  final _productsController = StreamController<List<ProductModel>>.broadcast();
  final _categoriesController = StreamController<List<CategoryModel>>.broadcast();

  ProductRepository() {
    final client = SupabaseService.client;
    if (client != null) {
      _initSupabaseSync();
      getProducts();
      getCategories();
    } else if (kDebugMode) {
      _products.addAll(testFallbackProducts);
      _categories.addAll(testFallbackCategories);
    }
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
      id: _uuid.v4(),
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
      id: _uuid.v4(),
      name: name,
      parentId: parentId,
      createdAt: DateTime.now(),
    );
    _categories.add(cat);
    _categoriesController.add(List.unmodifiable(_categories));
    return cat;
  }
}
