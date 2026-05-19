import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kids_stories/core/theme/tale_colors.dart';
import 'package:kids_stories/core/widgets/tale_button.dart';

/// Subscription / Paywall screen — shows premium plan options.
///
/// Actual RevenueCat integration is wired up separately; buttons currently
/// show a "Coming soon" snack bar.
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'TaleTrail Premium',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            color: TaleColors.warmGrey900,
            fontSize: 18,
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: TaleColors.warmGrey700),
            onPressed: () => context.pop(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [TaleColors.terracotta, TaleColors.warmGold],
                ),
              ),
              child: Column(
                children: [
                  const Text('📚', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 12),
                  const Text(
                    'TaleTrail Premium',
                    style: TextStyle(
                      fontFamily: 'Baloo2',
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Unlimited stories, new adventures every week',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 15,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Features list
                  const Text(
                    'What\'s included',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2E2720),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...[
                    'Unlimited access to all stories',
                    'New stories added every week',
                    'Offline downloads (up to 10 stories)',
                    'Up to 6 kid profiles',
                    'Reading reports & analytics',
                    'Reading streak tracking',
                    'Achievement badges',
                  ].map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const Text('✅', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              f,
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 15,
                                color: Color(0xFF2E2720),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Pricing cards
                  const Text(
                    'Choose your plan',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2E2720),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Monthly
                  _PlanCard(
                    title: 'Monthly',
                    price: '₹199',
                    period: '/month',
                    badge: '7-day free trial',
                    badgeColor: TaleColors.info,
                    isRecommended: false,
                    onTap: () => _showComingSoon(context),
                  ),

                  const SizedBox(height: 12),

                  // Annual (recommended)
                  _PlanCard(
                    title: 'Annual',
                    price: '₹1,499',
                    period: '/year',
                    badge: 'Save 37%',
                    badgeColor: TaleColors.success,
                    isRecommended: true,
                    onTap: () => _showComingSoon(context),
                  ),

                  const SizedBox(height: 32),

                  // CTA
                  TaleButton(
                    label: 'Start Free Trial',
                    onPressed: () => _showComingSoon(context),
                  ),

                  const SizedBox(height: 16),

                  // Restore
                  Center(
                    child: TextButton(
                      onPressed: () => _showComingSoon(context),
                      child: const Text(
                        'Restore Purchase',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          color: TaleColors.warmGrey500,
                        ),
                      ),
                    ),
                  ),

                  const Center(
                    child: Text(
                      'Cancel anytime. Terms & Privacy Policy apply.',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        color: TaleColors.warmGrey400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'In-app purchases coming soon! Stay tuned. 🎉',
          style: TextStyle(fontFamily: 'Nunito'),
        ),
        backgroundColor: TaleColors.info,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.badge,
    required this.badgeColor,
    required this.isRecommended,
    required this.onTap,
  });

  final String title;
  final String price;
  final String period;
  final String badge;
  final Color badgeColor;
  final bool isRecommended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRecommended
              ? TaleColors.terracotta.withOpacity(0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRecommended
                ? TaleColors.terracotta
                : TaleColors.warmGrey200,
            width: isRecommended ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2E2720),
                      ),
                    ),
                    if (isRecommended) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: TaleColors.terracotta,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Text(
                          'BEST VALUE',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2E2720),
                  ),
                ),
                Text(
                  period,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    color: TaleColors.warmGrey500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
