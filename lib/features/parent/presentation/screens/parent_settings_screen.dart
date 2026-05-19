import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kids_stories/core/navigation/app_router.dart';
import 'package:kids_stories/core/theme/tale_colors.dart';
import 'package:kids_stories/core/theme/app_dimensions.dart';
import 'package:kids_stories/features/auth/presentation/providers/auth_notifier_provider.dart';
import 'package:kids_stories/features/offline_library/presentation/providers/offline_library_provider.dart';

/// Full parent settings screen organized into labelled sections.
///
/// Sections:
///   Account — email, change password, sign out
///   Children — manage profiles
///   Reading — reports, notifications
///   Subscription — current plan, upgrade
///   Storage — offline downloads
///   App — version, privacy policy, terms of service
class ParentSettingsScreen extends ConsumerWidget {
  const ParentSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentEmail =
        FirebaseAuth.instance.currentUser?.email ?? '';

    // Storage usage from offline library
    final storageBytes = ref.watch(storageUsageProvider);
    final storageMb = (storageBytes / (1024 * 1024)).toStringAsFixed(1);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Parent Settings',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: TaleColors.warmGrey900,
          ),
        ),
        iconTheme: const IconThemeData(color: TaleColors.warmGrey700),
      ),
      body: ListView(
        children: [
          // ----------------------------------------------------------------
          // Account
          // ----------------------------------------------------------------
          const _SectionHeader('Account'),
          ListTile(
            leading: const Icon(
              Icons.email_outlined,
              color: TaleColors.warmGrey500,
            ),
            title: const Text(
              'Email',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              currentEmail.isNotEmpty ? currentEmail : '—',
              style: const TextStyle(
                fontFamily: 'Inter',
                color: TaleColors.warmGrey500,
                fontSize: 13,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.lock_outline,
              color: TaleColors.warmGrey500,
            ),
            title: const Text(
              'Change Password',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: TaleColors.warmGrey400,
            ),
            onTap: () async {
              if (currentEmail.isEmpty) return;
              try {
                final repo = ref.read(authRepositoryProvider);
                await repo.resetPassword(currentEmail);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Password reset email sent! Check your inbox.',
                      ),
                      backgroundColor: TaleColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to send reset email.'),
                      backgroundColor: TaleColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: TaleColors.error),
            title: const Text(
              'Sign Out',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                color: TaleColors.error,
              ),
            ),
            onTap: () => _confirmSignOut(context, ref),
          ),

          // ----------------------------------------------------------------
          // Children
          // ----------------------------------------------------------------
          const _SectionHeader('Children'),
          ListTile(
            leading: const Icon(
              Icons.child_care_rounded,
              color: TaleColors.warmGrey500,
            ),
            title: const Text(
              'Manage Profiles',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: TaleColors.warmGrey400,
            ),
            onTap: () => context.go(AppRoutes.parentProfiles),
          ),

          // ----------------------------------------------------------------
          // Reading
          // ----------------------------------------------------------------
          const _SectionHeader('Reading'),
          ListTile(
            leading: const Icon(
              Icons.bar_chart_rounded,
              color: TaleColors.warmGrey500,
            ),
            title: const Text(
              'Reading Reports',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: TaleColors.warmGrey400,
            ),
            onTap: () => context.go(AppRoutes.parentReports),
          ),
          ListTile(
            leading: const Icon(
              Icons.notifications_outlined,
              color: TaleColors.warmGrey500,
            ),
            title: const Text(
              'Notifications',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: TaleColors.warmGrey400,
            ),
            onTap: () => context.go(AppRoutes.parentNotifications),
          ),

          // ----------------------------------------------------------------
          // Subscription
          // ----------------------------------------------------------------
          const _SectionHeader('Subscription'),
          const ListTile(
            leading: Icon(
              Icons.star_outline_rounded,
              color: TaleColors.warmGrey500,
            ),
            title: Text(
              'Current Plan',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: Text(
              'Free',
              style: TextStyle(
                fontFamily: 'Inter',
                color: TaleColors.terracotta,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.upgrade_rounded,
              color: TaleColors.terracotta,
            ),
            title: const Text(
              'Upgrade to Premium',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                color: TaleColors.terracotta,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: TaleColors.terracotta,
            ),
            onTap: () => context.go(AppRoutes.parentSubscription),
          ),

          // ----------------------------------------------------------------
          // Storage
          // ----------------------------------------------------------------
          const _SectionHeader('Storage'),
          ListTile(
            leading: const Icon(
              Icons.download_for_offline_rounded,
              color: TaleColors.warmGrey500,
            ),
            title: const Text(
              'Download Storage',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              '$storageMb MB used',
              style: const TextStyle(
                fontFamily: 'Inter',
                color: TaleColors.warmGrey500,
                fontSize: 13,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.delete_outline_rounded,
              color: TaleColors.error,
            ),
            title: const Text(
              'Delete All Downloads',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                color: TaleColors.error,
              ),
            ),
            onTap: () => _confirmDeleteDownloads(context, ref),
          ),

          // ----------------------------------------------------------------
          // App
          // ----------------------------------------------------------------
          const _SectionHeader('App'),
          const ListTile(
            leading: Icon(
              Icons.info_outline_rounded,
              color: TaleColors.warmGrey500,
            ),
            title: Text(
              'App Version',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: Text(
              '1.0.0',
              style: TextStyle(
                fontFamily: 'Inter',
                color: TaleColors.warmGrey500,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.privacy_tip_outlined,
              color: TaleColors.warmGrey500,
            ),
            title: const Text(
              'Privacy Policy',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: const Icon(
              Icons.open_in_new_rounded,
              size: 16,
              color: TaleColors.warmGrey400,
            ),
            onTap: () {
              // Placeholder — url_launcher wired separately
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.description_outlined,
              color: TaleColors.warmGrey500,
            ),
            title: const Text(
              'Terms of Service',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: const Icon(
              Icons.open_in_new_rounded,
              size: 16,
              color: TaleColors.warmGrey400,
            ),
            onTap: () {
              // Placeholder — url_launcher wired separately
            },
          ),

          const SizedBox(height: TaleDimensions.paddingXxl),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Dialogs
  // ---------------------------------------------------------------------------

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Sign Out?',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'Your downloaded stories will remain on this device.',
          style: TextStyle(fontFamily: 'Nunito'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(fontFamily: 'Inter'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: TaleColors.error),
            child: const Text(
              'Sign Out',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(authNotifierProvider.notifier).signOut();
      if (context.mounted) {
        context.go(AppRoutes.login);
      }
    }
  }

  Future<void> _confirmDeleteDownloads(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Delete All Downloads?',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'This will remove all offline stories from this device. '
          'You can re-download them anytime.',
          style: TextStyle(fontFamily: 'Nunito'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(fontFamily: 'Inter'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: TaleColors.error),
            child: const Text(
              'Delete All',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(downloadNotifierProvider.notifier).deleteAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All downloads deleted.'),
            backgroundColor: TaleColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// _SectionHeader
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TaleDimensions.paddingMd,
        TaleDimensions.paddingMd,
        TaleDimensions.paddingMd,
        TaleDimensions.paddingXs,
      ),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: TaleColors.warmGrey500,
        ),
      ),
    );
  }
}
