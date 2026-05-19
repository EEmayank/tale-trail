import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kids_stories/core/theme/tale_colors.dart';
import 'package:kids_stories/core/theme/app_dimensions.dart';
import 'package:kids_stories/core/utils/constants.dart';
import 'package:kids_stories/features/auth/presentation/providers/auth_notifier_provider.dart';
import 'package:kids_stories/features/profile/presentation/providers/parental_gate_provider.dart';

// ---------------------------------------------------------------------------
// ParentalGateDialog
// ---------------------------------------------------------------------------

/// Shows a PIN verification dialog. On success calls [onVerified]; on
/// dismiss/cancel calls [onDismissed].
///
/// Usage:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (_) => ParentalGateDialog(
///     onVerified: () { /* proceed */ },
///     onDismissed: () {},
///   ),
/// );
/// ```
class ParentalGateDialog extends ConsumerStatefulWidget {
  const ParentalGateDialog({
    super.key,
    required this.onVerified,
    required this.onDismissed,
    this.redirectTo,
  });

  final VoidCallback onVerified;
  final VoidCallback onDismissed;
  final String? redirectTo;

  @override
  ConsumerState<ParentalGateDialog> createState() =>
      _ParentalGateDialogState();
}

class _ParentalGateDialogState extends ConsumerState<ParentalGateDialog>
    with SingleTickerProviderStateMixin {
  // ---------------------------------------------------------------------------
  // PIN state
  // ---------------------------------------------------------------------------

  String _pin = '';
  int _failedAttempts = 0;
  bool _useMathChallenge = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Shake animation
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  // Math challenge
  late int _mathA;
  late int _mathB;
  final _mathController = TextEditingController();
  String? _mathError;
  int _mathFailedAttempts = 0;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: -8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.linear));

    _generateMathChallenge();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _mathController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Math challenge
  // ---------------------------------------------------------------------------

  void _generateMathChallenge() {
    final rng = math.Random();
    _mathA = 10 + rng.nextInt(90); // 10–99
    _mathB = 10 + rng.nextInt(90); // 10–99
  }

  void _onMathSubmit() {
    final answer = int.tryParse(_mathController.text.trim());
    if (answer == null) {
      setState(() => _mathError = 'Please enter a number.');
      return;
    }

    if (answer == _mathA + _mathB) {
      _onVerified();
    } else {
      _mathFailedAttempts++;
      if (_mathFailedAttempts >= AppConstants.maxMathAttempts) {
        // Too many math failures — dismiss
        widget.onDismissed();
        if (mounted) Navigator.of(context).pop();
        return;
      }
      setState(() {
        _mathError =
            'Incorrect. ${AppConstants.maxMathAttempts - _mathFailedAttempts} attempt(s) left.';
        _mathController.clear();
      });
    }
  }

  // ---------------------------------------------------------------------------
  // PIN logic
  // ---------------------------------------------------------------------------

  void _onDigit(String digit) {
    if (_pin.length >= AppConstants.pinLength || _isLoading) return;
    setState(() {
      _pin += digit;
      _errorMessage = null;
    });
    if (_pin.length == AppConstants.pinLength) {
      _onPinComplete();
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty || _isLoading) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  Future<void> _onPinComplete() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(authRepositoryProvider);
      final isCorrect = await repo.verifyPin(uid, _pin);

      if (!mounted) return;

      if (isCorrect) {
        _onVerified();
      } else {
        _failedAttempts++;
        await _shakeController.forward(from: 0);

        if (_failedAttempts >= AppConstants.maxPinAttempts) {
          setState(() {
            _isLoading = false;
            _useMathChallenge = true;
            _pin = '';
          });
        } else {
          final remaining = AppConstants.maxPinAttempts - _failedAttempts;
          setState(() {
            _isLoading = false;
            _pin = '';
            _errorMessage = '$remaining attempt${remaining == 1 ? '' : 's'} left';
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _pin = '';
          _errorMessage = 'Verification failed. Try again.';
        });
      }
    }
  }

  void _onVerified() {
    ref.read(parentalGateStateProvider.notifier).verify();
    if (mounted) Navigator.of(context).pop();
    widget.onVerified();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      backgroundColor: TaleColors.parchment,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.all(TaleDimensions.paddingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              'Parent Verification 🔒',
              style: textTheme.headlineSmall?.copyWith(
                color: TaleColors.warmGrey900,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: TaleDimensions.paddingSm),

            Text(
              _useMathChallenge
                  ? 'Solve this to prove you\'re a parent'
                  : 'Enter your 4-digit parent PIN',
              style: textTheme.bodySmall?.copyWith(
                color: TaleColors.warmGrey600,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: TaleDimensions.paddingLg),

            // PIN UI or Math Challenge
            if (_useMathChallenge)
              _MathChallenge(
                a: _mathA,
                b: _mathB,
                controller: _mathController,
                error: _mathError,
                onSubmit: _onMathSubmit,
              )
            else ...[
              // Dot indicators
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) => Transform.translate(
                  offset: Offset(_shakeAnimation.value, 0),
                  child: child,
                ),
                child: _PinDots(
                  filled: _pin.length,
                  total: AppConstants.pinLength,
                  dotSize: 14,
                ),
              ),

              // Error
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _errorMessage != null
                    ? Padding(
                        key: ValueKey(_errorMessage),
                        padding: const EdgeInsets.only(
                            top: TaleDimensions.paddingSm),
                        child: Text(
                          _errorMessage!,
                          style: textTheme.labelSmall?.copyWith(
                            color: TaleColors.error,
                          ),
                        ),
                      )
                    : const SizedBox(height: 24),
              ),

              const SizedBox(height: TaleDimensions.paddingMd),

              // Compact numpad (48px)
              _isLoading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: TaleDimensions.paddingLg),
                      child: CircularProgressIndicator(
                        color: TaleColors.terracotta,
                        strokeWidth: 2.5,
                      ),
                    )
                  : _Numpad(
                      buttonSize: 48,
                      onDigit: _onDigit,
                      onBackspace: _onBackspace,
                    ),
            ],

            const SizedBox(height: TaleDimensions.paddingMd),

            // Cancel
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onDismissed();
              },
              child: Text(
                'Cancel',
                style: textTheme.labelMedium?.copyWith(
                  color: TaleColors.warmGrey500,
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
// Math challenge widget
// ---------------------------------------------------------------------------

class _MathChallenge extends StatelessWidget {
  const _MathChallenge({
    required this.a,
    required this.b,
    required this.controller,
    required this.onSubmit,
    this.error,
  });

  final int a;
  final int b;
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(
          'What is $a + $b?',
          style: textTheme.headlineMedium?.copyWith(
            color: TaleColors.warmGrey900,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: TaleDimensions.paddingMd),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Your answer',
            errorText: error,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TaleDimensions.radiusMd),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TaleDimensions.radiusMd),
              borderSide:
                  const BorderSide(color: TaleColors.terracotta, width: 2),
            ),
          ),
          onSubmitted: (_) => onSubmit(),
        ),
        const SizedBox(height: TaleDimensions.paddingMd),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: TaleColors.terracotta,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(TaleDimensions.radiusFull),
              ),
            ),
            onPressed: onSubmit,
            child: Text(
              'Submit',
              style: textTheme.labelLarge?.copyWith(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// PIN dots (shared widget)
// ---------------------------------------------------------------------------

class _PinDots extends StatelessWidget {
  const _PinDots({
    required this.filled,
    required this.total,
    this.dotSize = 18,
  });

  final int filled;
  final int total;
  final double dotSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final isFilled = index < filled;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            color: isFilled ? TaleColors.terracotta : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color:
                  isFilled ? TaleColors.terracotta : TaleColors.warmGrey400,
              width: 2,
            ),
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Numpad (shared widget)
// ---------------------------------------------------------------------------

class _Numpad extends StatelessWidget {
  const _Numpad({
    required this.buttonSize,
    required this.onDigit,
    required this.onBackspace,
  });

  final double buttonSize;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['*', '0', '⌫'],
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rows.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((label) {
            return _NumpadButton(
              label: label,
              size: buttonSize,
              onTap: label == '⌫'
                  ? onBackspace
                  : label == '*'
                      ? null
                      : () => onDigit(label),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}

class _NumpadButton extends StatelessWidget {
  const _NumpadButton({
    required this.label,
    required this.size,
    required this.onTap,
  });

  final String label;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isBackspace = label == '⌫';
    final isStar = label == '*';

    return Container(
      margin: const EdgeInsets.all(4),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isStar ? Colors.transparent : TaleColors.warmGrey100,
        borderRadius: BorderRadius.circular(TaleDimensions.radiusMd),
      ),
      child: isStar
          ? const SizedBox.shrink()
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius:
                    BorderRadius.circular(TaleDimensions.radiusMd),
                splashColor: TaleColors.terracotta.withAlpha(30),
                highlightColor: TaleColors.terracotta.withAlpha(15),
                child: Center(
                  child: isBackspace
                      ? Icon(
                          Icons.backspace_outlined,
                          size: size * 0.38,
                          color: TaleColors.warmGrey700,
                        )
                      : Text(
                          label,
                          style: TextStyle(
                            fontSize: size * 0.34,
                            fontWeight: FontWeight.w600,
                            color: TaleColors.warmGrey900,
                            fontFamily: 'Nunito',
                          ),
                        ),
                ),
              ),
            ),
    );
  }
}
