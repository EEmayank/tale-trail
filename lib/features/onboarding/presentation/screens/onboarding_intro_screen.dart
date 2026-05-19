import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kids_stories/core/theme/tale_colors.dart';
import 'package:kids_stories/core/theme/app_dimensions.dart';
import 'package:kids_stories/core/widgets/tale_button.dart';
import 'package:kids_stories/core/utils/constants.dart';

// ---------------------------------------------------------------------------
// Data model for each onboarding page
// ---------------------------------------------------------------------------

class _OnboardingPage {
  const _OnboardingPage({
    required this.gradientStart,
    required this.gradientEnd,
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  final Color gradientStart;
  final Color gradientEnd;
  final String emoji;
  final String title;
  final String subtitle;
}

const List<_OnboardingPage> _pages = [
  _OnboardingPage(
    gradientStart: TaleColors.terracotta,
    gradientEnd: TaleColors.warmGold,
    emoji: '📖',
    title: 'Magical Stories',
    subtitle:
        'Dive into a world of interactive tales where every choice shapes the adventure.',
  ),
  _OnboardingPage(
    gradientStart: TaleColors.oceanBlue,
    gradientEnd: TaleColors.spacePurple,
    emoji: '🌍',
    title: 'Explore Worlds',
    subtitle:
        'From enchanted forests to distant galaxies — limitless worlds await your child.',
  ),
  _OnboardingPage(
    gradientStart: TaleColors.forestGreen,
    gradientEnd: TaleColors.warmGold,
    emoji: '⭐',
    title: 'Made for Kids',
    subtitle:
        'Age-appropriate, ad-free stories crafted by educators and storytellers.',
  ),
];

// ---------------------------------------------------------------------------
// OnboardingScreen
// ---------------------------------------------------------------------------

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyHasLaunchedBefore, true);
    if (mounted) {
      context.go('/signup');
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _complete();
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full-screen PageView
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) =>
                _OnboardingPageView(page: _pages[index]),
          ),

          // Skip button — top right
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: TaleDimensions.paddingMd,
                  right: TaleDimensions.paddingLg,
                ),
                child: TextButton(
                  onPressed: _complete,
                  child: Text(
                    'Skip',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          shadows: [
                            const Shadow(
                              color: Colors.black26,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom controls: dots + button
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: TaleDimensions.paddingXl,
                  right: TaleDimensions.paddingXl,
                  bottom: TaleDimensions.paddingXl,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dot indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (index) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 24 : 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? TaleColors.terracotta
                                : Colors.white.withAlpha(128),
                            borderRadius: BorderRadius.circular(
                                TaleDimensions.radiusFull),
                            border: _currentPage == index
                                ? null
                                : Border.all(
                                    color: Colors.white.withAlpha(180),
                                    width: 1.5,
                                  ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: TaleDimensions.paddingLg),

                    // Next / Get Started button
                    TaleButton(
                      label: _currentPage == _pages.length - 1
                          ? 'Get Started'
                          : 'Next',
                      onPressed: _nextPage,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Individual page widget
// ---------------------------------------------------------------------------

class _OnboardingPageView extends StatelessWidget {
  const _OnboardingPageView({required this.page});

  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [page.gradientStart, page.gradientEnd],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // Large emoji
            Text(
              page.emoji,
              style: const TextStyle(fontSize: 100),
            ),

            const SizedBox(height: TaleDimensions.paddingXl),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: TaleDimensions.paddingXl),
              child: Text(
                page.title,
                textAlign: TextAlign.center,
                style: textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  shadows: [
                    const Shadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: TaleDimensions.paddingMd),

            // Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: TaleDimensions.paddingXl),
              child: Text(
                page.subtitle,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withAlpha(230),
                  height: 1.5,
                ),
              ),
            ),

            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}
