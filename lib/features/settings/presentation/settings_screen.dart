import 'package:flutter/foundation.dart';
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

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out from this terminal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('SIGN OUT'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(currentProfileProvider.notifier).signOut();
    }
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
          'Settings & Account',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (kDebugMode)
            IconButton(
              tooltip: 'Debug Switcher',
              icon: const Icon(Icons.bug_report_outlined, color: AppColors.warning),
              onPressed: () => SellerSwitcherModal.show(context),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        children: [
          // Current User Card
          AppCard(
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: currentProfile?.isAdmin == true ? AppColors.secondary : AppColors.primary,
                      child: Text(
                        (currentProfile?.name ?? 'U').substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentProfile?.name ?? 'Authenticated User',
                            style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Role: ${currentProfile?.role.name.toUpperCase()}',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: currentProfile?.isAdmin == true ? AppColors.secondary : AppColors.primary,
                            ),
                          ),
                          Text(
                            currentProfile?.email ?? '',
                            style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondaryLight),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _handleSignOut,
                    icon: const Icon(Icons.logout, color: AppColors.error, size: 18),
                    label: Text(
                      'SIGN OUT FROM TERMINAL',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        color: AppColors.error,
                        fontSize: 13,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Cloud Sync Status Card
          AppCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isLiveConnected ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isLiveConnected ? Icons.cloud_done : Icons.cloud_off,
                    color: isLiveConnected ? AppColors.success : AppColors.warning,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cloud Sync Status',
                        style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        isLiveConnected
                            ? 'Connected to Supabase PostgreSQL'
                            : 'Offline / Connecting...',
                        style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLiveConnected ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isLiveConnected ? 'LIVE' : 'OFFLINE',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isLiveConnected ? AppColors.success : AppColors.warning,
                    ),
                  ),
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
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('System Architecture', style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondaryLight)),
                    Text('Multi-Terminal POS', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('App Version', style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondaryLight)),
                    Text('2.1.0 (Production)', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),

          // Developer Controls (Gated exclusively to Debug Builds)
          if (kDebugMode) ...[
            const SizedBox(height: 20),
            ExpansionTile(
              title: Text(
                'Developer Tools (Debug Mode Only)',
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.warning),
              ),
              leading: const Icon(Icons.code, color: AppColors.warning),
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _urlController,
                        decoration: const InputDecoration(labelText: 'Supabase URL'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _anonKeyController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Anon Key'),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _isSaving ? null : _saveSupabaseCredentials,
                        child: const Text('RECONNECT CLIENT'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
