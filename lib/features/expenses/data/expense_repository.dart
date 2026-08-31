import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/supabase_service.dart';
import '../domain/expense_model.dart';

class ExpenseRepository {
  final _uuid = const Uuid();
  final List<ExpenseModel> _expenses = [];
  final _expensesController = StreamController<List<ExpenseModel>>.broadcast();

  ExpenseRepository() {
    _seedInitialExpenses();
    _initSupabaseSync();
  }

  void _seedInitialExpenses() {
    final now = DateTime.now();
    _expenses.addAll([
      ExpenseModel(
        id: 'exp-1',
        category: 'Transport',
        description: 'Rice delivery from farm / warehouse',
        amount: 500.0,
        expenseDate: now,
        createdBy: '00000000-0000-0000-0000-000000000001',
        createdByName: 'Admin',
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
      ExpenseModel(
        id: 'exp-2',
        category: 'Packaging',
        description: 'Cloth bags & paper packaging rolls',
        amount: 350.0,
        expenseDate: now,
        createdBy: '00000000-0000-0000-0000-000000000001',
        createdByName: 'Admin',
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
    ]);
  }

  void _initSupabaseSync() {
    final client = SupabaseService.client;
    if (client != null) {
      client
          .channel('public:expenses')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'expenses',
            callback: (payload) {
              refreshExpenses();
            },
          )
          .subscribe();
    }
  }

  Stream<List<ExpenseModel>> get expensesStream {
    Timer.run(() => _expensesController.add(List.unmodifiable(_expenses)));
    return _expensesController.stream;
  }

  Future<List<ExpenseModel>> getExpenses() async {
    final client = SupabaseService.client;
    if (client != null) {
      try {
        final res = await client
            .from('expenses')
            .select('*, profiles:created_by(name)')
            .order('expense_date', ascending: false);

        final fetched = (res as List).map((e) => ExpenseModel.fromJson(e)).toList();
        _expenses.clear();
        _expenses.addAll(fetched);
        _expensesController.add(List.unmodifiable(_expenses));
        return _expenses;
      } catch (e) {
        debugPrint('Error fetching expenses from Supabase: $e');
      }
    }
    return List.unmodifiable(_expenses);
  }

  Future<void> refreshExpenses() async {
    await getExpenses();
  }

  Future<ExpenseModel> addExpense({
    required String category,
    required String? description,
    required double amount,
    required DateTime date,
    required String userId,
    required String userName,
  }) async {
    if (amount <= 0) {
      throw Exception('Expense amount must be greater than zero.');
    }

    final client = SupabaseService.client;
    if (client != null) {
      try {
        final res = await client
            .from('expenses')
            .insert({
              'category': category,
              'description': description,
              'amount': amount,
              'expense_date': date.toIso8601String().split('T')[0],
              'created_by': userId,
            })
            .select('*, profiles:created_by(name)')
            .single();

        final created = ExpenseModel.fromJson(res);
        _expenses.insert(0, created);
        _expensesController.add(List.unmodifiable(_expenses));
        return created;
      } catch (e) {
        debugPrint('Supabase add expense error: $e');
      }
    }

    final localExp = ExpenseModel(
      id: 'exp-${_uuid.v4().substring(0, 8)}',
      category: category,
      description: description,
      amount: amount,
      expenseDate: date,
      createdBy: userId,
      createdByName: userName,
      createdAt: DateTime.now(),
    );

    _expenses.insert(0, localExp);
    _expensesController.add(List.unmodifiable(_expenses));
    return localExp;
  }
}
