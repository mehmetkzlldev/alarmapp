import 'package:flutter/material.dart';

/// Centered loading spinner with an optional label. Use as the body of a
/// screen while data loads, or inline within a card.
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({this.label, this.size = 28, super.key});

  final String? label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: const CircularProgressIndicator(strokeWidth: 3),
          ),
          if (label != null) ...[
            const SizedBox(height: 12),
            Text(label!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}
