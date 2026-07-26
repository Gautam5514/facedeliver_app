import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

/// Labelled text input. The label sits above the field as a small uppercase
/// eyebrow, matching the web forms.
class AppField extends StatelessWidget {
  const AppField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.icon,
    this.keyboardType,
    this.obscure = false,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.validator,
    this.enabled = true,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
    this.helper,
    this.trailing,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final bool obscure;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final bool enabled;
  final List<String>? autofillHints;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;
  final String? helper;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label.toUpperCase(), style: AppText.eyebrow)),
            ?trailing,
          ],
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          enabled: enabled,
          obscureText: obscure,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          validator: validator,
          autofillHints: autofillHints,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          style: AppText.bodyStrong,
          cursorColor: AppColors.ink,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(left: 14, right: 10),
                    child: Icon(icon, size: 18, color: AppColors.faint),
                  ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 6),
          Text(helper!, style: AppText.micro),
        ],
      ],
    );
  }
}

/// Validators shared across the auth and event forms.
class Validate {
  const Validate._();

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Email is required';
    // Mirrors the server-side check in guestController.
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// The API rejects anything shorter than 8 characters.
  static String? password(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Password is required';
    if (text.length < 8) return 'Use at least 8 characters';
    return null;
  }

  /// Event codes travel inside QR links and become the public key for every
  /// guest lookup, so keep them URL-safe and unambiguous.
  static String? eventCode(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Event code is required';
    if (text.length < 3) return 'Use at least 3 characters';
    if (!RegExp(r'^[a-z0-9-]+$').hasMatch(text)) {
      return 'Only lowercase letters, numbers and hyphens';
    }
    return null;
  }
}
