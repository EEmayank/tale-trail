import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kids_stories/core/theme/tale_colors.dart';
import 'package:kids_stories/core/theme/app_dimensions.dart';
import 'package:kids_stories/core/utils/constants.dart';
import 'package:kids_stories/features/auth/presentation/providers/auth_notifier_provider.dart';

// ---------------------------------------------------------------------------
// SetupPinScreen
// ---------------------------------------------------------------------------

class SetupPinScreen extends ConsumerStatefulWidget {
  const SetupPinScreen({super.key});

  @override
  ConsumerState<SetupPinScreen> createState() => _SetupPinScreenState();
}

class _SetupPinScreenState extends ConsumerState<SetupPinScreen>
    with SingleTickerProviderStateMixin {
  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  /// Whether we're in confirmation phase (true) or entry phase (false).
  bool _isConfirming = false;

  String _pin = '';
  String _firstPin = '';
  String? _errorMessage;
  bool _isLoading = false;

  // Shake animation
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

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
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Numpad logic
  // ---------------------------------------------------------------------------

  void _onDigit(String digit) {
    if (_pin.length >= AppConstants.pinLength) return;
    setState(() {
      _pin += digit;
      _errorMessage = null;
    });

    if (_pin.length == AppConstants.pinLength) {
      _onPinComplete();
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _errorMessage = null;
    });
  }

  Future<void> _onPinComplete() async {
    if (!_isConfirming) {
      // Phase 1 → Phase 2
      await Future.delayed(const Duration(milliseconds: 150));
      setState(() {
        _firstPin = _pin;
        _pin = '';
        _isConfirming = true;
      });
      return;
    }

    // Phase 2: confirm
    if (_pin != _firstPin) {
      await _shakeController.forward(from: 0);
      setState(() {
        _pin = '';
        _firstPin = '';
        _isConfirming = false;
        _errorMessage = 'PINs don\'t match. Please try again.';
      });
      return;
    }

    // Success — save
    await _savePin(_pin);
  }

  Future<void> _savePin(String pin) async {
    final uid = ref.read(authNotifierProvider).user?.uid;
    if (uid == null) {
      context.go('/profiles');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.setupPin(uid, pin);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pinSetup', true);

      if (mounted) {
        context.go('/profiles');
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _pin = '';
          _firstPin = '';
          _isConfirming = false;
          _errorMessage = 'Failed to save PIN. Please try again.';
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: TaleColors.parchment,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: TaleColors.terracotta,
                ),
              )
            : Column(
                children: [
                  const SizedBox(height: TaleDimensions.paddingXl),

                  // Lock icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: TaleColors.terracotta.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('🔒', style: TextStyle(fontSize: 36)),
                    ),
                  ),

                  const SizedBox(height: TaleDimensions.paddingLg),

                  // Title
                  Text(
                    _isConfirming ? 'Confirm your PIN' : 'Set Parent PIN',
                    style: textTheme.headlineMedium?.copyWith(
                      color: TaleColors.warmGrey900,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: TaleDimensions.paddingMd),

                  // Subtitle
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: TaleDimensions.paddingXl),
                    child: Text(
                      _isConfirming
                          ? 'Enter your PIN again to confirm'
                          : 'Choose a 4-digit PIN to keep your settings safe',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: TaleColors.warmGrey600,
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: TaleDimensions.paddingXl),

                  // Dot indicators with shake animation
                  AnimatedBuilder(
                    animation: _shakeAnimation,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(_shakeAnimation.value, 0),
                      child: child,
                    ),
                    child: _PinDots(
                      filled: _pin.length,
                      total: AppConstants.pinLength,
                    ),
                  ),

                  // Error message
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _errorMessage != null
                        ? Padding(
                            key: ValueKey(_errorMessage),
                            padding: const EdgeInsets.only(
                                top: TaleDimensions.paddingMd),
                            child: Text(
                              _errorMessage!,
                              style: textTheme.labelMedium?.copyWith(
                                color: TaleColors.error,
                              ),
                            ),
                          )
                        : const SizedBox(height: TaleDimensions.paddingMd + 20),
                  ),

                  const Spacer(),

                  // Numpad
                  _Numpad(
                    buttonSize: 64,
                    onDigit: _onDigit,
                    onBackspace: _onBackspace,
                  ),

                  const SizedBox(height: TaleDimensions.paddingLg),

                  // Skip button
                  TextButton(
                    onPressed: () => context.go('/profiles'),
                    child: Text(
                      'Skip for now',
                      style: textTheme.labelLarge?.copyWith(
                        color: TaleColors.warmGrey500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: TaleDimensions.paddingLg),
                ],
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PIN Dots indicator
// ---------------------------------------------------------------------------

class _PinDots extends StatelessWidget {
  const _PinDots({required this.filled, required this.total});

  final int filled;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final isFilled = index < filled;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 18,
          height: 18,
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
// Numpad
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
    // Row order: [1,2,3], [4,5,6], [7,8,9], [*,0,⌫]
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
      margin: const EdgeInsets.all(6),
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
                borderRadius: BorderRadius.circular(TaleDimensions.radiusMd),
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
