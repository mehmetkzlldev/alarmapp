import 'package:flutter/material.dart';

import 'package:alarmy/l10n/app_localizations.dart';

import '../../../../core/error/failures.dart';

/// Renders a presentation-safe error message extracted from an [Object] error
/// (typically a [Failure] from the auth notifier). Returns an empty widget when
/// [error] is null.
class AuthErrorText extends StatelessWidget {
  const AuthErrorText({super.key, required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    if (error == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final message = error is Failure
        ? (error as Failure).message
        : l10n.authGenericError;

    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: scheme.onErrorContainer, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
