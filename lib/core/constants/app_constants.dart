class AppConstants {
  static const String appName = 'Nammalvar Iyerkai Angadi';
  static const String appTagline = 'இயற்கை அங்காடி • Pure & Traditional';

  // Supabase Config Keys (Can also be overridden via runtime or dart-define)
  static const String defaultSupabaseUrl = 'https://your-project.supabase.co';
  static const String defaultSupabaseAnonKey = 'your-anon-key';

  // Currency
  static const String currencySymbol = '₹';

  // Units
  static const List<String> units = [
    'kg',
    'g',
    'litre',
    'ml',
    'piece',
    'packet',
    'bottle',
    'box',
  ];

  // Payment Methods
  static const List<String> paymentMethods = [
    'cash',
    'upi',
    'other',
  ];

  // Expense Categories
  static const List<String> expenseCategories = [
    'Transport',
    'Packaging',
    'Electricity',
    'Maintenance',
    'Rent',
    'Salary/Wages',
    'Supplies',
    'Other',
  ];
}
