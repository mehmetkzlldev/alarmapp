import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:alarmy/l10n/app_localizations.dart';
import '../../../alarms/domain/entities/alarm_mission_entity.dart';
import '../../domain/entities/math_problem.dart';
import '../../domain/usecases/generate_math.dart';
import '../../domain/usecases/verify_math.dart';
import '../providers/mission_providers.dart';

/// A single math mission. Fetches a problem from `/missions/math/generate`,
/// lets the user type an answer, and verifies it via `/missions/math/verify`.
///
/// On a correct answer it calls [onSolved]; the parent [MissionScreen] forwards
/// that to the sequence controller to advance/dismiss.
class MathMission extends ConsumerStatefulWidget {
  const MathMission({
    super.key,
    required this.mission,
    required this.onSolved,
    required this.onFailed,
  });

  final AlarmMissionEntity mission;

  /// Invoked when the answer is verified correct.
  final VoidCallback onSolved;

  /// Invoked on a wrong answer (the widget itself loads a fresh problem so the
  /// user cannot brute-force by re-submitting).
  final ValueChanged<String> onFailed;

  @override
  ConsumerState<MathMission> createState() => _MathMissionState();
}

enum _MathPhase { loading, ready, verifying, error }

class _MathMissionState extends ConsumerState<MathMission> {
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  _MathPhase _phase = _MathPhase.loading;
  MathProblem? _problem;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadProblem();
  }

  @override
  void dispose() {
    _answerController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadProblem() async {
    setState(() {
      _phase = _MathPhase.loading;
      _loadError = null;
      _answerController.clear();
    });

    final GenerateMath generate = ref.read(generateMathProvider);
    final result = await generate(
      GenerateMathParams(difficulty: widget.mission.difficulty),
    );

    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _phase = _MathPhase.error;
        _loadError = failure.message;
      }),
      (problem) => setState(() {
        _problem = problem;
        _phase = _MathPhase.ready;
        // Auto-focus so the keyboard is up immediately when the alarm fires.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _focusNode.requestFocus();
        });
      }),
    );
  }

  Future<void> _submit() async {
    final problem = _problem;
    if (problem == null) return;

    final l10n = AppLocalizations.of(context);
    final raw = _answerController.text.trim();
    final parsed = int.tryParse(raw);
    if (parsed == null) {
      widget.onFailed(l10n.missionEnterANumber);
      return;
    }

    setState(() => _phase = _MathPhase.verifying);

    final VerifyMath verify = ref.read(verifyMathProvider);
    final result = await verify(
      VerifyMathParams(problemId: problem.problemId, answer: parsed),
    );

    if (!mounted) return;
    await result.fold(
      (failure) async {
        // Network/server error — let the user retry the same problem.
        setState(() => _phase = _MathPhase.ready);
        widget.onFailed(failure.message);
      },
      (correct) async {
        if (correct) {
          widget.onSolved();
        } else {
          widget.onFailed(l10n.missionWrongAnswer);
          await _loadProblem(); // fresh problem -> no brute forcing.
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    switch (_phase) {
      case _MathPhase.loading:
        return const Center(child: CircularProgressIndicator());
      case _MathPhase.error:
        return _ErrorRetry(
          message: _loadError ?? l10n.missionFailedToLoadProblem,
          onRetry: _loadProblem,
        );
      case _MathPhase.ready:
      case _MathPhase.verifying:
        final problem = _problem!;
        final verifying = _phase == _MathPhase.verifying;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.missionSolveToDismiss,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              Text(
                problem.expression,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _answerController,
                focusNode: _focusNode,
                enabled: !verifying,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(signed: true),
                inputFormatters: [
                  // Allow an optional leading minus then digits only.
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
                ],
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium,
                decoration: InputDecoration(
                  hintText: l10n.missionAnswerHint,
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => verifying ? null : _submit(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: verifying ? null : _submit,
                  child: verifying
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.missionSubmit),
                ),
              ),
            ],
          ),
        );
    }
  }
}

/// Small inline error + retry used by mission widgets.
class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonal(
                onPressed: onRetry, child: Text(l10n.missionRetry)),
          ],
        ),
      ),
    );
  }
}
