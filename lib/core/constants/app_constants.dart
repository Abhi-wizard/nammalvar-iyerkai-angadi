class AppConstants {
  static const String appName = 'Nammalvar Iyerkai Angadi';
  static const String appTagline = 'இயற்கை அங்காடி • Pure & Traditional';

  // Supabase Config Keys
  static const String defaultSupabaseUrl = 'https://snxltzbkkdghmaggzhdh.supabase.co';
  static const String defaultSupabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNueGx0emJra2RnaG1hZ2d6aGRoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODgxNjM1MTUsImV4cCI6MjEwMzczOTUxNX0.ym2E-xqYyqfwE6zCFuuGfvNHvDbmakPoen_1TsncJh0';

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
