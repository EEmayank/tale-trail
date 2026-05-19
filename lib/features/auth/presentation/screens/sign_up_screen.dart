import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kids_stories/core/theme/app_dimensions.dart';
import 'package:kids_stories/core/theme/tale_colors.dart';
import 'package:kids_stories/core/widgets/tale_button.dart';
import 'package:kids_stories/features/auth/presentation/providers/auth_notifier_provider.dart';
import 'package:kids_stories/features/auth/presentation/widgets/auth_form_field.dart';

/// Sign-up screen where new parents create an account.
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  // Track whether the form has been submitted once (to show inline errors).
  bool _submitted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Validators
  // ---------------------------------------------------------------------------

  String? _validateName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter your name.';
    if (v.length < 1 || v.length > 50) {
      return 'Name must be between 1 and 50 characters.';
    }
    return null;
  }

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
    final v = value ?? '';
    if (v.isEmpty) return 'Please enter a password.';
    if (v.length < 8) return 'Password must be at least 8 characters.';
    if (!RegExp(r'[a-zA-Z]').hasMatch(v)) {
      return 'Password must contain at least one letter.';
    }
    if (!RegExp(r'[0-9]').hasMatch(v)) {
      return 'Password must contain at least one number.';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) {
      return 'Passwords do not match.';
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
    await authNotifier.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      displayName: _nameController.text.trim(),
    );

    // Navigate on success — check if still mounted and no error.
    if (mounted) {
      final state = ref.read(authNotifierProvider);
      if (state.error == null && state.user != null) {
        context.go('/onboarding');
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
                context.go('/login');
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

                  // Title
                  Text(
                    'Create Account',
                    style: tt.displaySmall?.copyWith(
                      color: TaleColors.warmGrey900,
                    ),
                  ),
                  const SizedBox(height: TaleDimensions.paddingSm),
                  Text(
                    'Start your family\'s reading adventure.',
                    style: tt.bodyMedium?.copyWith(
                      color: TaleColors.warmGrey600,
                    ),
                  ),
                  const SizedBox(height: TaleDimensions.paddingXl),

                  // Name
                  AuthFormField(
                    controller: _nameController,
                    label: 'Your name',
                    hint: 'e.g. Alex Smith',
                    focusNode: _nameFocus,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.name,
                    autofillHints: const [AutofillHints.name],
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    validator: _validateName,
                    onFieldSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_emailFocus),
                  ),
                  const SizedBox(height: TaleDimensions.paddingMd),

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
                    hint: 'At least 8 characters',
                    isPassword: true,
                    focusNode: _passwordFocus,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    validator: _validatePassword,
                    onFieldSubmitted: (_) => FocusScope.of(context)
                        .requestFocus(_confirmPasswordFocus),
                  ),
                  const SizedBox(height: TaleDimensions.paddingMd),

                  // Confirm password
                  AuthFormField(
                    controller: _confirmPasswordController,
                    label: 'Confirm password',
                    hint: 'Re-enter your password',
                    isPassword: true,
                    focusNode: _confirmPasswordFocus,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    validator: _validateConfirmPassword,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: TaleDimensions.paddingXl),

                  // Submit button
                  TaleButton(
                    label: 'Create Account',
                    onPressed: authState.isLoading ? null : _submit,
                    isLoading: authState.isLoading,
                  ),

                  // Inline error
                  if (authState.error != null) ...[
                    const SizedBox(height: TaleDimensions.paddingMd),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(TaleDimensions.paddingMd),
                      decoration: BoxDecoration(
                        color: TaleColors.error.withAlpha(20),
                        borderRadius:
                            BorderRadius.circular(TaleDimensions.radiusMd),
                        border: Border.all(
                          color: TaleColors.error.withAlpha(77),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: TaleColors.error,
                            size: TaleDimensions.iconSizeMd,
                          ),
                          const SizedBox(width: TaleDimensions.paddingSm),
                          Expanded(
                            child: Text(
                              authState.error!,
                              style: tt.bodySmall?.copyWith(
                                color: TaleColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: TaleDimensions.paddingXl),

                  // Sign-in link
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/login'),
                      child: RichText(
                        text: TextSpan(
                          style: tt.bodySmall?.copyWith(
                            color: TaleColors.warmGrey600,
                          ),
                          children: [
                            const TextSpan(text: 'Already have an account? '),
                            TextSpan(
                              text: 'Sign In',
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
