import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/seller_switcher_modal.dart';
import '../../auth/presentation/auth_providers.dart';
import '../domain/expense_model.dart';
import 'expense_providers.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentProfile = ref.watch(currentProfileProvider);
    final expensesAsync = ref.watch(expensesStreamProvider);
    final todayTotal = ref.watch(todayExpensesTotalProvider);
    final isAdmin = currentProfile?.isAdmin == true;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Shop Expenses',
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
              tooltip: 'Add Expense',
              icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 28),
              onPressed: () => _showAddExpenseModal(context, ref),
            ),
        ],
      ),
      body: Column(
        children: [
          // Total Card
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TODAY\'S EXPENSES', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    Text(
                      Formatters.currency(todayTotal),
                      style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary),
                    ),
                  ],
                ),
                if (isAdmin)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('ADD'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(90, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onPressed: () => _showAddExpenseModal(context, ref),
                  ),
              ],
            ),
          ),

          // Expense List
          Expanded(
            child: expensesAsync.maybeWhen(
              data: (expenses) {
                if (expenses.isEmpty) {
                  return Center(
                    child: Text('No expenses recorded', style: GoogleFonts.outfit(color: AppColors.textSecondaryLight)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final exp = expenses[index];
                    return _buildExpenseCard(exp);
                  },
                );
              },
              orElse: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(ExpenseModel exp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Icons.account_balance_wallet_outlined, color: AppColors.error, size: 22),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exp.category,
                    style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimaryLight),
                  ),
                  if (exp.description != null && exp.description!.isNotEmpty) ...[
                    Text(
                      exp.description!,
                      style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondaryLight),
                    ),
                  ],
                  Text(
                    '${Formatters.formatDate(exp.expenseDate)} • Added by ${exp.createdByName ?? "Admin"}',
                    style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondaryLight),
                  ),
                ],
              ),
            ),
            Text(
              Formatters.currency(exp.amount),
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.error),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddExpenseModal(BuildContext context, WidgetRef ref) {
    final amountController = TextEditingController();
    final descController = TextEditingController();
    String selectedCategory = AppConstants.expenseCategories.first;
    final currentProfile = ref.read(currentProfileProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Record Shop Expense', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                decoration: const InputDecoration(labelText: 'Expense Category *'),
                items: AppConstants.expenseCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) {
                  if (val != null) selectedCategory = val;
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Amount (₹) *',
                  prefixText: '₹ ',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description / Purpose (Optional)',
                  hintText: 'e.g., Rice delivery truck fare',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(amountController.text.trim());
                  if (amount != null && amount > 0) {
                    Navigator.pop(ctx);
                    final repo = ref.read(expenseRepositoryProvider);
                    await repo.addExpense(
                      category: selectedCategory,
                      description: descController.text.trim(),
                      amount: amount,
                      date: DateTime.now(),
                      userId: currentProfile?.id ?? '00000000-0000-0000-0000-000000000001',
                      userName: currentProfile?.name ?? 'Admin',
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Expense saved.'), backgroundColor: AppColors.success),
                      );
                    }
                  }
                },
                child: const Text('SAVE EXPENSE'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
