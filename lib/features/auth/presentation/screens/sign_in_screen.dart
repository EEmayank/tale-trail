import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kids_stories/core/theme/app_dimensions.dart';
import 'package:kids_stories/core/theme/tale_colors.dart';
import 'package:kids_stories/core/widgets/tale_button.dart';
import 'package:kids_stories/features/auth/presentation/providers/auth_notifier_provider.dart';
import 'package:kids_stories/features/auth/presentation/widgets/auth_form_field.dart';
import 'package:kids_stories/features/auth/presentation/widgets/google_sign_in_button.dart';

/// Sign-in screen for returning parents.
///
/// Accepts an optional [redirectTo] path to navigate to after successful login.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.redirectTo});

  /// If set, the user is sent here instead of `/profiles` after signing in.
  final String? redirectTo;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _submitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Validators
  // ---------------------------------------------------------------------------

  String? _validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter your email address.';
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(v)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password.';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Submit
  // ---------------------------------------------------------------------------

  Future<void> _submit() async {
    setState(() => _submitted = true);
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final authNotifier = ref.read(authNotifierProvider.notifier);
    await authNotifier.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (mounted) {
      final state = ref.read(authNotifierProvider);
      if (state.error == null && state.user != null) {
        context.go(widget.redirectTo ?? '/profiles');
      }
    }
  }

  Future<void> _googleSignIn() async {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    await authNotifier.signInWithGoogle();

    if (mounted) {
      final state = ref.read(authNotifierProvider);
      if (state.error == null && state.user != null) {
        context.go(widget.redirectTo ?? '/profiles');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final tt = Theme.of(context).textTheme;

    // Show error SnackBar
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
                  ref
                      .read(authNotifierProvider.notifier)
                      .clearError();
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
        backgroundColor: TaleColors.parchment,
        appBar: AppBar(
          backgroundColor: TaleColors.parchment,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: TaleColors.warmGrey700,
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: TaleDimensions.paddingXl,
            ),
            child: Form(
              key: _formKey,
              autovalidateMode: _submitted
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: TaleDimensions.paddingSm),

                  // Title + subtitle
                  Text(
                    'Welcome Back',
                    style: tt.displaySmall?.copyWith(
                      color: TaleColors.warmGrey900,
                    ),
                  ),
                  const SizedBox(height: TaleDimensions.paddingSm),
                  Text(
                    'Sign in to continue your story.',
                    style: tt.bodyMedium?.copyWith(
                      color: TaleColors.warmGrey600,
                    ),
                  ),
                  const SizedBox(height: TaleDimensions.paddingXl),

                  // Email
                  AuthFormField(
                    controller: _emailController,
                    label: 'Email address',
                    hint: 'you@example.com',
                    focusNode: _emailFocus,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    prefixIcon: const Icon(Icons.email_outlined),
                    validator: _validateEmail,
                    onFieldSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_passwordFocus),
                  ),
                  const SizedBox(height: TaleDimensions.paddingMd),

                  // Password
                  AuthFormField(
                    controller: _passwordController,
                    label: 'Password',
                    isPassword: true,
                    focusNode: _passwordFocus,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    validator: _validatePassword,
                    onFieldSubmitted: (_) => _submit(),
                  ),

                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push('/forgot-password'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: TaleDimensions.paddingXs,
                          vertical: TaleDimensions.paddingXs,
                        ),
                      ),
                      child: Text(
                        'Forgot password?',
                        style: tt.bodySmall?.copyWith(
                          color: TaleColors.terracotta,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: TaleDimensions.paddingMd),

                  // Sign-in button
                  TaleButton(
                    label: 'Sign In',
                    onPressed: authState.isLoading ? null : _submit,
                    isLoading: authState.isLoading,
                  ),
                  const SizedBox(height: TaleDimensions.paddingLg),

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
                  const SizedBox(height: TaleDimensions.paddingLg),

                  // Google sign-in
                  GoogleSignInButton(
                    isLoading: authState.isLoading,
                    onPressed:
                        authState.isLoading ? null : _googleSignIn,
                  ),
                  const SizedBox(height: TaleDimensions.paddingXl),

                  // Sign-up link
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/signup'),
                      child: RichText(
                        text: TextSpan(
                          style: tt.bodySmall?.copyWith(
                            color: TaleColors.warmGrey600,
                          ),
                          children: [
                            const TextSpan(
                                text: 'Don\'t have an account? '),
                            TextSpan(
                              text: 'Sign Up',
                              style: tt.bodySmall?.copyWith(
                                color: TaleColors.terracotta,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: TaleDimensions.paddingLg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
