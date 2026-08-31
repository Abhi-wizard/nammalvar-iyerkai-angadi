import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/seller_switcher_modal.dart';
import '../../auth/presentation/auth_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _urlController;
  late TextEditingController _anonKeyController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: SupabaseConfig.currentUrl);
    _anonKeyController = TextEditingController(text: SupabaseConfig.currentAnonKey);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _anonKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveSupabaseCredentials() async {
    setState(() => _isSaving = true);
    try {
      await SupabaseConfig.saveCredentials(_urlController.text, _anonKeyController.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Supabase credentials saved. Reconnecting...'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Config error: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentProfile = ref.watch(currentProfileProvider);
    final isLiveConnected = SupabaseService.isLive;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Settings & Cloud Sync',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Switch User',
            icon: const Icon(Icons.switch_account_outlined, color: AppColors.primary),
            onPressed: () => SellerSwitcherModal.show(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        children: [
          // Current User Card
          AppCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: currentProfile?.isAdmin == true ? AppColors.secondary : AppColors.primary,
                  child: Text(
                    (currentProfile?.name ?? 'U').substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentProfile?.name ?? 'User',
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Role: ${currentProfile?.role.name.toUpperCase()} • ${currentProfile?.email ?? ""}',
                        style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () => SellerSwitcherModal.show(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(80, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: const Text('SWITCH', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Supabase Connection Status Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isLiveConnected ? Icons.cloud_done : Icons.cloud_queue,
                          color: isLiveConnected ? AppColors.success : AppColors.warning,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Supabase Cloud Backend',
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isLiveConnected ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isLiveConnected ? 'CONNECTED' : 'LOCAL MOCK / READY',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isLiveConnected ? AppColors.success : AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Text(
                  'Central PostgreSQL Database URL',
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    hintText: 'https://xxxxxxxxxxxxxx.supabase.co',
                    prefixIcon: Icon(Icons.link, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Supabase Anon Key (Public Key)',
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _anonKeyController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
                    prefixIcon: Icon(Icons.vpn_key_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save_outlined),
                  label: _isSaving
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white))
                      : const Text('CONNECT / SAVE CREDENTIALS'),
                  onPressed: _isSaving ? null : _saveSupabaseCredentials,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Database Migrations Info Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.storage_outlined, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text('SQL Migrations Ready', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Schema & seed files are stored in:\n• supabase/migrations/00001_initial_schema.sql\n• supabase/migrations/00002_seed_data.sql',
                  style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondaryLight),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Store Info Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppConstants.appName, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary)),
                Text(AppConstants.appTagline, style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondaryLight)),
                const SizedBox(height: 8),
                Text('Multi-device version: 2.0 (Production Ready)', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondaryLight)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
