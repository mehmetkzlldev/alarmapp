import 'package:flutter/material.dart';

import 'package:alarmy/l10n/app_localizations.dart';

/// A styled, reusable text field for the auth forms.
///
/// Wraps [TextFormField] with consistent decoration, optional password
/// obscuring with a visibility toggle, and pass-through validation.
class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onFieldSubmitted,
    this.enabled = true,
    this.autofillHints,
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;
  final Iterable<String>? autofillHints;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late bool _obscured = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscured,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      onFieldSubmitted: widget.onFieldSubmitted,
      enabled: widget.enabled,
      autofillHints: widget.autofillHints,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hintText,
        prefixIcon:
            widget.prefixIcon == null ? null : Icon(widget.prefixIcon),
        border: const OutlineInputBorder(),
        // Show a visibility toggle only for password-style fields.
        suffixIcon: widget.obscureText
            ? IconButton(
                tooltip:
                    _obscured ? l10n.authShowPassword : l10n.authHidePassword,
                icon: Icon(
                  _obscured ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setState(() => _obscured = !_obscured),
              )
            : null,
      ),
    );
  }
}
