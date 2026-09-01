import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_constants.dart';
import 'core/network/supabase_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_providers.dart';
import 'features/auth/presentation/login_screen.dart';
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

class NammalvarApp extends ConsumerWidget {
  const NammalvarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentProfile = ref.watch(currentProfileProvider);
    final client = SupabaseService.client;
    final hasActiveSession = client?.auth.currentSession != null;

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: currentProfile != null
          ? const MainNavigationShell()
          : (hasActiveSession
              ? const Scaffold(
                  backgroundColor: AppColors.backgroundLight,
                  body: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              : const LoginScreen()),
    );
  }
}
