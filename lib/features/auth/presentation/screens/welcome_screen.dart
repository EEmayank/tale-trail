import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kids_stories/core/theme/app_dimensions.dart';
import 'package:kids_stories/core/theme/tale_colors.dart';
import 'package:kids_stories/core/widgets/tale_button.dart';
import 'package:kids_stories/features/auth/presentation/providers/auth_notifier_provider.dart';
import 'package:kids_stories/features/auth/presentation/widgets/google_sign_in_button.dart';

/// The initial landing screen for unauthenticated users.
///
/// Displays the TaleTrail brand, then offers three entry points:
/// create an account, sign in with email, or continue with Google.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final authNotifier = ref.read(authNotifierProvider.notifier);
    final tt = Theme.of(context).textTheme;
    final size = MediaQuery.sizeOf(context);

    // Show SnackBar whenever a new error arrives.
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.error!),
              backgroundColor: TaleColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(TaleDimensions.radiusMd),
              ),
              action: SnackBarAction(
                label: 'Dismiss',
                textColor: Colors.white,
                onPressed: () {
                  authNotifier.clearError();
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
      }
    });

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: Stack(
          children: [
            // -----------------------------------------------------------------
            // Gradient background
            // -----------------------------------------------------------------
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      TaleColors.terracotta,
                      TaleColors.terracottaDark,
                      Color(0xFFD97B66), // mid-point
                      TaleColors.warmGoldDark,
                      TaleColors.warmGold,
                    ],
                    stops: [0.0, 0.2, 0.45, 0.75, 1.0],
                  ),
                ),
              ),
            ),

            // Subtle decorative circles for depth.
            Positioned(
              top: -size.width * 0.25,
              right: -size.width * 0.2,
              child: _DecorativeCircle(
                diameter: size.width * 0.7,
                color: Colors.white.withAlpha(18),
              ),
            ),
            Positioned(
              bottom: size.height * 0.3,
              left: -size.width * 0.3,
              child: _DecorativeCircle(
                diameter: size.width * 0.6,
                color: Colors.white.withAlpha(13),
              ),
            ),

            // -----------------------------------------------------------------
            // Content
            // -----------------------------------------------------------------
            SafeArea(
              child: Column(
                children: [
                  // ---- Logo / title area ----
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: TaleDimensions.paddingXl,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Book / story icon
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(38),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text(
                                  '📖',
                                  style: TextStyle(fontSize: 48),
                                ),
                              ),
                            ),
                            const SizedBox(height: TaleDimensions.paddingLg),
                            Text(
                              'TaleTrail',
                              style: tt.displayLarge?.copyWith(
                                color: Colors.white,
                                fontFamily: 'Baloo2',
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withAlpha(51),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: TaleDimensions.paddingSm),
                            Text(
                              'Stories that branch',
                              style: tt.bodyLarge?.copyWith(
                                color: Colors.white.withAlpha(204),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ---- Bottom action card ----
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: TaleColors.parchment,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(TaleDimensions.radiusXl),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(31),
                          blurRadius: 24,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(
                      TaleDimensions.paddingXl,
                      TaleDimensions.paddingXl,
                      TaleDimensions.paddingXl,
                      TaleDimensions.paddingLg,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Drag handle
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(
                            bottom: TaleDimensions.paddingLg,
                          ),
                          decoration: BoxDecoration(
                            color: TaleColors.warmGrey300,
                            borderRadius: BorderRadius.circular(
                              TaleDimensions.radiusFull,
                            ),
                          ),
                        ),

                        // Create Account
                        TaleButton(
                          label: 'Create Account',
                          onPressed: () => context.go('/signup'),
                          isPrimary: true,
                        ),
                        const SizedBox(height: TaleDimensions.paddingMd),

                        // Sign In
                        TaleButton(
                          label: 'Sign In',
                          onPressed: () => context.go('/login'),
                          isPrimary: false,
                        ),
                        const SizedBox(height: TaleDimensions.paddingMd),

                        // Divider
                        Row(
                          children: [
                            const Expanded(
                              child: Divider(
                                color: TaleColors.warmGrey300,
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: TaleDimensions.paddingMd,
                              ),
                              child: Text(
                                'or',
                                style: tt.bodySmall?.copyWith(
                                  color: TaleColors.warmGrey500,
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Divider(
                                color: TaleColors.warmGrey300,
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: TaleDimensions.paddingMd),

                        // Google sign-in
                        GoogleSignInButton(
                          isLoading: authState.isLoading,
                          onPressed: authState.isLoading
                              ? null
                              : () => authNotifier.signInWithGoogle(),
                        ),
                        const SizedBox(height: TaleDimensions.paddingLg),

                        // Privacy policy caption
                        Text(
                          'By continuing you agree to our Privacy Policy',
                          style: tt.labelSmall?.copyWith(
                            color: TaleColors.warmGrey500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // -----------------------------------------------------------------
            // Full-screen loading overlay
            // -----------------------------------------------------------------
            if (authState.isLoading)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withAlpha(64),
                  child: const Center(
                    child: CircularProgressIndicator.adaptive(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------

class _DecorativeCircle extends StatelessWidget {
  const _DecorativeCircle({required this.diameter, required this.color});

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: diameter,
      height: diameter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
