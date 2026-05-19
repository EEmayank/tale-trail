import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kids_stories/core/theme/app_dimensions.dart';
import 'package:kids_stories/core/theme/tale_colors.dart';
import 'package:kids_stories/core/widgets/tale_button.dart';
import 'package:kids_stories/features/auth/presentation/providers/auth_notifier_provider.dart';
import 'package:kids_stories/features/auth/presentation/widgets/auth_form_field.dart';

/// Screen for requesting a password reset email.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _emailFocus = FocusNode();

  bool _submitted = false;
  bool _resetSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Validator
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

  // ---------------------------------------------------------------------------
  // Submit
  // ---------------------------------------------------------------------------

  Future<void> _submit() async {
    setState(() => _submitted = true);
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final authNotifier = ref.read(authNotifierProvider.notifier);
    await authNotifier.resetPassword(_emailController.text.trim());

    if (mounted) {
      final state = ref.read(authNotifierProvider);
      if (state.error == null) {
        setState(() => _resetSent = true);
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
          title: Text(
            'Forgot Password',
            style: tt.titleMedium?.copyWith(
              color: TaleColors.warmGrey800,
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(TaleDimensions.paddingXl),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _resetSent
                  ? _SuccessView(
                      key: const ValueKey('success'),
                      email: _emailController.text.trim(),
                      onBackToLogin: () => context.go('/login'),
                    )
                  : _FormView(
                      key: const ValueKey('form'),
                      formKey: _formKey,
                      emailController: _emailController,
                      emailFocus: _emailFocus,
                      submitted: _submitted,
                      authState: authState,
                      validateEmail: _validateEmail,
                      onSubmit: _submit,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _FormView
// ---------------------------------------------------------------------------

class _FormView extends StatelessWidget {
  const _FormView({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.emailFocus,
    required this.submitted,
    required this.authState,
    required this.validateEmail,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final FocusNode emailFocus;
  final bool submitted;
  final AuthState authState;
  final FormFieldValidator<String> validateEmail;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Form(
      key: formKey,
      autovalidateMode: submitted
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Illustration
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: TaleColors.terracotta.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🔑', style: TextStyle(fontSize: 40)),
              ),
            ),
          ),
          const SizedBox(height: TaleDimensions.paddingXl),

          // Title + description
          Text(
            'Reset your password',
            style: tt.headlineLarge?.copyWith(
              color: TaleColors.warmGrey900,
            ),
          ),
          const SizedBox(height: TaleDimensions.paddingSm),
          Text(
            'Enter the email address associated with your account and '
            'we\'ll send you a link to reset your password.',
            style: tt.bodyMedium?.copyWith(
              color: TaleColors.warmGrey600,
            ),
          ),
          const SizedBox(height: TaleDimensions.paddingXl),

          // Email field
          AuthFormField(
            controller: emailController,
            label: 'Email address',
            hint: 'you@example.com',
            focusNode: emailFocus,
            textInputAction: TextInputAction.done,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            prefixIcon: const Icon(Icons.email_outlined),
            validator: validateEmail,
            onFieldSubmitted: (_) => onSubmit(),
          ),
          const SizedBox(height: TaleDimensions.paddingXl),

          // Submit button
          TaleButton(
            label: 'Send Reset Link',
            onPressed: authState.isLoading ? null : onSubmit,
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

          // Back to sign-in
          Center(
            child: TextButton.icon(
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  context.go('/login');
                }
              },
              icon: const Icon(
                Icons.arrow_back_rounded,
                size: TaleDimensions.iconSizeSm,
                color: TaleColors.terracotta,
              ),
              label: Text(
                'Back to Sign In',
                style: tt.bodySmall?.copyWith(
                  color: TaleColors.terracotta,
                  fontWeight: FontWeight.w600,
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
// _SuccessView
// ---------------------------------------------------------------------------

class _SuccessView extends StatelessWidget {
  const _SuccessView({
    super.key,
    required this.email,
    required this.onBackToLogin,
  });

  final String email;
  final VoidCallback onBackToLogin;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: TaleDimensions.paddingXl),

        // Success icon
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: TaleColors.success.withAlpha(26),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.mark_email_read_outlined,
              color: TaleColors.success,
              size: 48,
            ),
          ),
        ),
        const SizedBox(height: TaleDimensions.paddingXl),

        Text(
          'Check your email',
          style: tt.headlineLarge?.copyWith(
            color: TaleColors.warmGrey900,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: TaleDimensions.paddingMd),

        Text(
          'We sent a password reset link to',
          style: tt.bodyMedium?.copyWith(
            color: TaleColors.warmGrey600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: TaleDimensions.paddingXs),
        Text(
          email,
          style: tt.bodyMedium?.copyWith(
            color: TaleColors.warmGrey900,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: TaleDimensions.paddingSm),
        Text(
          'If you don\'t see it, please check your spam folder.',
          style: tt.bodySmall?.copyWith(
            color: TaleColors.warmGrey500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: TaleDimensions.paddingXxl),

        TaleButton(
          label: 'Back to Sign In',
          onPressed: onBackToLogin,
        ),
      ],
    );
  }
}
