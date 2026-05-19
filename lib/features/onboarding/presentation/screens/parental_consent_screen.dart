import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kids_stories/core/theme/tale_colors.dart';
import 'package:kids_stories/core/theme/app_dimensions.dart';
import 'package:kids_stories/core/widgets/tale_button.dart';
import 'package:kids_stories/features/auth/presentation/providers/auth_notifier_provider.dart';

// ---------------------------------------------------------------------------
// Privacy bullet data
// ---------------------------------------------------------------------------

const List<String> _privacyBullets = [
  'We don\'t collect personal information from children',
  'No ads, no tracking, no social features',
  'Stories are safe and age-appropriate',
  'Parents control all account settings',
  'Compliant with COPPA and India\'s DPDP Act',
];

// ---------------------------------------------------------------------------
// ParentalConsentScreen
// ---------------------------------------------------------------------------

class ParentalConsentScreen extends ConsumerStatefulWidget {
  const ParentalConsentScreen({super.key});

  @override
  ConsumerState<ParentalConsentScreen> createState() =>
      _ParentalConsentScreenState();
}

class _ParentalConsentScreenState extends ConsumerState<ParentalConsentScreen> {
  bool _isConsentChecked = false;
  bool _isLoading = false;

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _onContinue() async {
    if (!_isConsentChecked) return;

    final authState = ref.read(authNotifierProvider);
    final uid = authState.user?.uid;
    if (uid == null) {
      if (mounted) context.go('/signup');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.recordConsent(uid);
      if (mounted) {
        context.go('/profiles/add');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save consent. Please try again.'),
            backgroundColor: TaleColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: TaleColors.terracotta,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'A Note for Parents',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(TaleDimensions.paddingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header illustration / icon area
                    Center(
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: TaleColors.warmGold.withAlpha(60),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            '🔒',
                            style: TextStyle(fontSize: 44),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: TaleDimensions.paddingLg),

                    // Intro heading
                    Text(
                      'Your child\'s privacy matters',
                      style: textTheme.headlineMedium?.copyWith(
                        color: TaleColors.warmGrey900,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: TaleDimensions.paddingMd),

                    Text(
                      'TaleTrail is designed with children\'s safety at its core. Before your child starts their reading adventure, please take a moment to review our commitments:',
                      style: textTheme.bodyMedium?.copyWith(
                        color: TaleColors.warmGrey700,
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: TaleDimensions.paddingLg),

                    // Privacy bullets
                    Container(
                      decoration: BoxDecoration(
                        color: TaleColors.parchment,
                        borderRadius: BorderRadius.circular(
                            TaleDimensions.radiusMd),
                        border: Border.all(
                          color: TaleColors.warmGrey200,
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(TaleDimensions.paddingLg),
                      child: Column(
                        children: _privacyBullets.map((bullet) {
                          return Padding(
                            padding: const EdgeInsets.only(
                                bottom: TaleDimensions.paddingMd),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                    color: TaleColors.success,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: TaleDimensions.paddingMd),
                                Expanded(
                                  child: Text(
                                    bullet,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: TaleColors.warmGrey800,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: TaleDimensions.paddingLg),

                    // Additional info
                    Text(
                      'Full Privacy Policy',
                      style: textTheme.labelMedium?.copyWith(
                        color: TaleColors.terracotta,
                        decoration: TextDecoration.underline,
                        decorationColor: TaleColors.terracotta,
                      ),
                    ),

                    const SizedBox(height: TaleDimensions.paddingXxl),
                  ],
                ),
              ),
            ),

            // Bottom consent area
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(TaleDimensions.paddingLg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Checkbox row
                  InkWell(
                    onTap: () =>
                        setState(() => _isConsentChecked = !_isConsentChecked),
                    borderRadius:
                        BorderRadius.circular(TaleDimensions.radiusSm),
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: _isConsentChecked
                                  ? TaleColors.terracotta
                                  : Colors.white,
                              border: Border.all(
                                color: _isConsentChecked
                                    ? TaleColors.terracotta
                                    : TaleColors.warmGrey400,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: _isConsentChecked
                                ? const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(width: TaleDimensions.paddingMd),
                          Expanded(
                            child: Text(
                              'I understand and consent for my child to use TaleTrail',
                              style:
                                  Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: TaleColors.warmGrey800,
                                        fontWeight: FontWeight.w600,
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: TaleDimensions.paddingLg),

                  // Continue button
                  TaleButton(
                    label: 'Continue',
                    onPressed: _isConsentChecked ? _onContinue : null,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
