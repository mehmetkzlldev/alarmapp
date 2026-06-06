import 'package:equatable/equatable.dart';

/// Pure domain entity for a generated math problem.
///
/// Mirrors `POST /missions/math/generate` ->
/// `{ problemId, expression, operandCount }`.
///
/// SECURITY: the correct answer is NEVER sent to the client; it is cached
/// server-side in Redis keyed by [problemId] and only checked via
/// `POST /missions/math/verify`.
class MathProblem extends Equatable {
  const MathProblem({
    required this.problemId,
    required this.expression,
    required this.operandCount,
  });

  /// Opaque id used to verify the answer against the server-cached solution.
  final String problemId;

  /// Human-readable expression to display, e.g. "12 + 7 × 3".
  final String expression;

  /// Number of operands — used purely for UI hints / analytics.
  final int operandCount;

  @override
  List<Object?> get props => [problemId, expression, operandCount];
}
