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

/// Account creation screen (email, display name, password + confirmation).
///
/// Submits to [AuthNotifier.register]. Like the login screen, navigation on
/// success is handled by the router listening to [authNotifierProvider].
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key, this.onNavigateToLogin});

  /// Optional callback to switch back to the login screen.
  final VoidCallback? onNavigateToLogin;

  static const String routeName = 'register';
  static const String routePath = '/register';

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    await ref.read(authNotifierProvider.notifier).register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _displayNameController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;
    final l10n = AppLocalizations.of(context);

    ref.listen<AsyncValue<AuthState>>(authNotifierProvider, (prev, next) {
      if (next.hasError && !next.isLoading) {
        final message = next.error is Failure
            ? (next.error as Failure).message
            : l10n.authRegistrationFailed;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.authRegisterTitle)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.authRegisterSubtitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 24),

                      if (authState.hasError && !isLoading)
                        AuthErrorText(error: authState.error),

                      AuthTextField(
                        controller: _displayNameController,
                        label: l10n.authDisplayNameLabel,
                        prefixIcon: Icons.person_outline,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        validator: (v) => AuthValidators.displayName(v, l10n),
                        enabled: !isLoading,
                      ),
                      const SizedBox(height: 16),

                      AuthTextField(
                        controller: _emailController,
                        label: l10n.authEmailLabel,
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        validator: (v) => AuthValidators.email(v, l10n),
                        enabled: !isLoading,
                      ),
                      const SizedBox(height: 16),

                      AuthTextField(
                        controller: _passwordController,
                        label: l10n.authPasswordLabel,
                        prefixIcon: Icons.lock_outline,
                        obscureText: true,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newPassword],
                        validator: (v) => AuthValidators.password(v, l10n),
                        enabled: !isLoading,
                      ),
                      const SizedBox(height: 16),

                      AuthTextField(
                        controller: _confirmController,
                        label: l10n.authConfirmPasswordLabel,
                        prefixIcon: Icons.lock_outline,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        validator: AuthValidators.confirmPassword(
                          () => _passwordController.text,
                          l10n,
                        ),
                        onFieldSubmitted: (_) => _submit(),
                        enabled: !isLoading,
                      ),
                      const SizedBox(height: 24),

                      PrimaryButton(
                        label: l10n.authCreateAccountButton,
                        isLoading: isLoading,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(l10n.authHaveAccountPrompt),
                          TextButton(
                            onPressed:
                                isLoading ? null : widget.onNavigateToLogin,
                            child: Text(l10n.authSignInButton),
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
