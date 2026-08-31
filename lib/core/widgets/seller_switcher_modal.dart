import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../theme/app_colors.dart';

class SellerSwitcherModal extends ConsumerWidget {
  const SellerSwitcherModal({super.key});

  static void show(BuildContext context) {
    if (!kDebugMode) {
      debugPrint('SellerSwitcherModal is disabled in release/production builds.');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const SellerSwitcherModal(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    final currentProfile = ref.watch(currentProfileProvider);
    final profiles = AuthRepository.mockProfiles;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.bug_report_outlined, color: AppColors.warning),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Debug Multi-Seller Switcher',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      'DEVELOPMENT ONLY • Hidden in production builds',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...profiles.map((profile) {
            final isSelected = currentProfile?.id == profile.id;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryContainer.withValues(alpha: 0.35) : AppColors.surfaceVariantLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onTap: () {
                  ref.read(currentProfileProvider.notifier).switchSellerInDebug(profile);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Switched active debug user to: ${profile.name}'),
                      backgroundColor: AppColors.primary,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                leading: CircleAvatar(
                  backgroundColor: profile.isAdmin ? AppColors.secondary : AppColors.primary,
                  child: Text(
                    profile.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  profile.name,
                  style: GoogleFonts.outfit(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                subtitle: Text(
                  '${profile.role.name.toUpperCase()} • ${profile.email ?? ''}',
                  style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondaryLight),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : const Icon(Icons.chevron_right, color: AppColors.textSecondaryLight),
              ),
            );
          }),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
