import 'package:alarmy/l10n/app_localizations.dart';

/// Pure, synchronous form validators for the auth screens.
///
/// These mirror the backend's DTO constraints so the user gets instant
/// feedback, but the server remains authoritative (class-validator on the API).
///
/// Message strings are looked up via the [AppLocalizations] instance passed in
/// by the calling screen (which has a [BuildContext]); the regex/logic here
/// stays context-free.
class AuthValidators {
  AuthValidators._();

  // Reasonable email shape; intentionally permissive (RFC-perfect regex is not
  // worth the complexity — the backend does the strict check).
  static final RegExp _emailRegExp =
      RegExp(r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,}$');

  /// Returns an error message, or null when valid.
  static String? email(String? value, AppLocalizations l10n) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return l10n.authEmailRequired;
    if (!_emailRegExp.hasMatch(v)) return l10n.authEmailInvalid;
    return null;
  }

  /// Password rule mirrors the backend: min 8 chars, at least one letter and
  /// one number.
  static String? password(String? value, AppLocalizations l10n) {
    final v = value ?? '';
    if (v.isEmpty) return l10n.authPasswordRequired;
    if (v.length < 8) return l10n.authPasswordMinLength(8);
    final hasLetter = v.contains(RegExp(r'[A-Za-z]'));
    final hasNumber = v.contains(RegExp(r'\d'));
    if (!hasLetter || !hasNumber) {
      return l10n.authPasswordComplexity;
    }
    return null;
  }

  /// Confirm-password validator factory: capture the original controller value.
  static String? Function(String?) confirmPassword(
    String Function() original,
    AppLocalizations l10n,
  ) {
    return (String? value) {
      if ((value ?? '').isEmpty) return l10n.authConfirmPasswordRequired;
      if (value != original()) return l10n.authPasswordsDoNotMatch;
      return null;
    };
  }

  static String? displayName(String? value, AppLocalizations l10n) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return l10n.authDisplayNameRequired;
    if (v.length < 2) return l10n.authDisplayNameTooShort;
    if (v.length > 50) return l10n.authDisplayNameTooLong;
    return null;
  }
}
