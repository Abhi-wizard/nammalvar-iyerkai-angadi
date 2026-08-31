import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_constants.dart';
import 'core/network/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/presentation/main_navigation_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.init();

  runApp(
    const ProviderScope(
      child: NammalvarApp(),
    ),
  );
}

class NammalvarApp extends StatelessWidget {
  const NammalvarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainNavigationShell(),
    );
  }
}
