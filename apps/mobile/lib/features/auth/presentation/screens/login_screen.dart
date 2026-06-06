import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:alarmy/l10n/app_localizations.dart';

import '../../../../core/error/failures.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';
import '../utils/auth_validators.dart';
import '../widgets/auth_error_text.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/primary_button.dart';

/// Email/password sign-in screen.
///
/// Submits to [AuthNotifier.login]. Loading and error states are derived from
/// the notifier's [AsyncValue]; on success the router (listening to
/// [authNotifierProvider]) navigates away, so this screen does not push routes
/// itself.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.onNavigateToRegister});

  /// Optional callback to switch to the register screen. Wired by the router so
  /// this screen stays navigation-agnostic.
  final VoidCallback? onNavigateToRegister;

  /// Named route convenience for go_router registration.
  static const String routeName = 'login';
  static const String routePath = '/login';

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Validate the form before hitting the network.
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    await ref.read(authNotifierProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;
    final l10n = AppLocalizations.of(context);

    // Surface auth errors as a SnackBar in addition to the inline banner.
    ref.listen<AsyncValue<AuthState>>(authNotifierProvider, (prev, next) {
      if (next.hasError && !next.isLoading) {
        final message = next.error is Failure
            ? (next.error as Failure).message
            : l10n.authLoginFailed;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(
                        title: l10n.authWelcomeBackTitle,
                        subtitle: l10n.authWelcomeBackSubtitle,
                      ),
                      const SizedBox(height: 32),

                      // Inline error banner (mirrors the SnackBar).
                      if (authState.hasError && !isLoading)
                        AuthErrorText(error: authState.error),

                      AuthTextField(
                        controller: _emailController,
                        label: l10n.authEmailLabel,
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.username],
                        validator: (v) => AuthValidators.email(v, l10n),
                        enabled: !isLoading,
                      ),
                      const SizedBox(height: 16),

                      AuthTextField(
                        controller: _passwordController,
                        label: l10n.authPasswordLabel,
                        prefixIcon: Icons.lock_outline,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        validator: (v) => (v == null || v.isEmpty)
                            ? l10n.authPasswordRequired
                            : null,
                        onFieldSubmitted: (_) => _submit(),
                        enabled: !isLoading,
                      ),
                      const SizedBox(height: 24),

                      PrimaryButton(
                        label: l10n.authSignInButton,
                        isLoading: isLoading,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(l10n.authNoAccountPrompt),
                          TextButton(
                            onPressed: isLoading
                                ? null
                                : widget.onNavigateToRegister,
                            child: Text(l10n.authCreateOneButton),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small title/subtitle header shared by the auth screens.
class _Header extends StatelessWidget {
  const _Header({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.alarm, size: 48, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text(title, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
