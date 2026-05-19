import 'package:flutter/material.dart';
import 'package:kids_stories/core/theme/app_dimensions.dart';
import 'package:kids_stories/core/theme/tale_colors.dart';

/// A styled text form field used across all auth screens.
///
/// Features:
/// - Rounded border using [TaleColors] and [TaleDimensions].
/// - Nunito font via the app [TextTheme].
/// - Password visibility toggle when [isPassword] is `true`.
/// - Full validation support via [validator].
class AuthFormField extends StatefulWidget {
  const AuthFormField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.isPassword = false,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.autofillHints,
    this.prefixIcon,
    this.enabled = true,
    this.focusNode,
  });

  /// The editing controller.
  final TextEditingController controller;

  /// Label text shown floating above the field.
  final String label;

  /// Optional placeholder text inside the field.
  final String? hint;

  /// When `true`, the field obscures text and shows a visibility toggle.
  final bool isPassword;

  /// Form validation callback. Return `null` for valid input.
  final FormFieldValidator<String>? validator;

  /// Keyboard type (e.g. [TextInputType.emailAddress]).
  final TextInputType? keyboardType;

  /// Action button shown on the keyboard (e.g. [TextInputAction.next]).
  final TextInputAction? textInputAction;

  /// Called when the user submits the field via the keyboard action button.
  final ValueChanged<String>? onFieldSubmitted;

  /// Autofill hints for system-level password management.
  final Iterable<String>? autofillHints;

  /// Optional leading icon inside the field.
  final Widget? prefixIcon;

  /// Whether the field is interactive.
  final bool enabled;

  /// Optional external focus node.
  final FocusNode? focusNode;

  @override
  State<AuthFormField> createState() => _AuthFormFieldState();
}

class _AuthFormFieldState extends State<AuthFormField> {
  bool _obscureText = true;

  void _toggleVisibility() {
    setState(() => _obscureText = !_obscureText);
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isObscured = widget.isPassword && _obscureText;

    return TextFormField(
      controller: widget.controller,
      obscureText: isObscured,
      validator: widget.validator,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      autofillHints: widget.autofillHints,
      enabled: widget.enabled,
      focusNode: widget.focusNode,
      style: tt.bodyMedium?.copyWith(
        color: TaleColors.warmGrey900,
        fontFamily: 'Nunito',
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        hintStyle: tt.bodyMedium?.copyWith(
          color: TaleColors.warmGrey400,
          fontFamily: 'Nunito',
        ),
        labelStyle: tt.bodyMedium?.copyWith(
          color: TaleColors.warmGrey600,
          fontFamily: 'Nunito',
        ),
        floatingLabelStyle: tt.bodySmall?.copyWith(
          color: TaleColors.terracotta,
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: widget.prefixIcon != null
            ? IconTheme(
                data: const IconThemeData(
                  color: TaleColors.warmGrey400,
                  size: TaleDimensions.iconSizeMd,
                ),
                child: widget.prefixIcon!,
              )
            : null,
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  isObscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: TaleColors.warmGrey500,
                  size: TaleDimensions.iconSizeMd,
                ),
                onPressed: _toggleVisibility,
                splashRadius: 20,
                tooltip: isObscured ? 'Show password' : 'Hide password',
              )
            : null,
        filled: true,
        fillColor: widget.enabled
            ? TaleColors.warmWhite
            : TaleColors.warmGrey100,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: TaleDimensions.paddingMd,
          vertical: TaleDimensions.paddingMd,
        ),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(TaleDimensions.radiusMd),
          borderSide: const BorderSide(
            color: TaleColors.warmGrey300,
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(TaleDimensions.radiusMd),
          borderSide: const BorderSide(
            color: TaleColors.warmGrey300,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(TaleDimensions.radiusMd),
          borderSide: const BorderSide(
            color: TaleColors.terracotta,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(TaleDimensions.radiusMd),
          borderSide: const BorderSide(
            color: TaleColors.error,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(TaleDimensions.radiusMd),
          borderSide: const BorderSide(
            color: TaleColors.error,
            width: 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(TaleDimensions.radiusMd),
          borderSide: const BorderSide(
            color: TaleColors.warmGrey200,
            width: 1.5,
          ),
        ),
        errorStyle: tt.bodySmall?.copyWith(
          color: TaleColors.error,
          fontFamily: 'Nunito',
        ),
      ),
    );
  }
}
