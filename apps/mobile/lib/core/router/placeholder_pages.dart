import 'package:flutter/material.dart';

/// Lightweight placeholder scaffold used by the router until feature teams wire
/// in their real screens. Keeping these here lets the skeleton compile and run
/// end-to-end (navigation, redirects) before any feature UI exists.
///
/// Feature agents should REPLACE the corresponding route's builder in
/// [appRouter] with their own screen widget — do not build production UI here.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({
    required this.title,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.construction_outlined,
                  size: 48, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(title, style: theme.textTheme.headlineSmall),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
