import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/expense_repository.dart';
import '../domain/expense_model.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository();
});

final expensesStreamProvider = StreamProvider<List<ExpenseModel>>((ref) {
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.expensesStream;
});

// Total Expenses Today
final todayExpensesTotalProvider = Provider<double>((ref) {
  final expensesAsync = ref.watch(expensesStreamProvider);
  final now = DateTime.now();

  return expensesAsync.maybeWhen(
    data: (expenses) {
      return expenses.where((e) {
        final eDate = e.expenseDate.toLocal();
        return eDate.year == now.year &&
            eDate.month == now.month &&
            eDate.day == now.day;
      }).fold(0.0, (sum, item) => sum + item.amount);
    },
    orElse: () => 0.0,
  );
});
