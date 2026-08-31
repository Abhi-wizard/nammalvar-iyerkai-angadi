class ExpenseModel {
  final String id;
  final String category;
  final String? description;
  final double amount;
  final DateTime expenseDate;
  final String createdBy;
  final DateTime createdAt;

  // Joined fields
  final String? createdByName;

  ExpenseModel({
    required this.id,
    required this.category,
    this.description,
    required this.amount,
    required this.expenseDate,
    required this.createdBy,
    required this.createdAt,
    this.createdByName,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as String,
      category: json['category'] as String,
      description: json['description'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      expenseDate: json['expense_date'] != null
          ? DateTime.parse(json['expense_date'] as String)
          : DateTime.now(),
      createdBy: json['created_by'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      createdByName: json['profiles'] != null ? json['profiles']['name'] as String? : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'description': description,
      'amount': amount,
      'expense_date': expenseDate.toIso8601String().split('T')[0],
      'created_by': createdBy,
    };
  }
}
