import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:alarmy/l10n/app_localizations.dart';
import '../../../alarms/domain/entities/alarm_mission_entity.dart';
import '../../domain/entities/object_detection_result.dart';
import '../../domain/usecases/verify_object.dart';
import '../providers/mission_providers.dart';

/// Household objects the wake-up "find an object" mission can ask for. Mirrors
/// the backend SUPPORTED_OBJECTS allow-list, so Gemini recognizes each target.
const List<String> kSupportedDetectionObjects = <String>[
  'toothbrush',
  'coffee mug',
  'keys',
  'shoes',
  'laptop',
  'sink',
];

/// Object-detection mission: the user photographs a real-world object to prove
/// they are out of bed.
///
/// Two modes:
///   * **Specific target** (e.g. "toothbrush") on a real device — the photo is
///     uploaded to S3 and verified by the backend (Gemini vision); only an
///     `isMatch == true` result passes.
///   * **Demo / "any object"** — used for the in-browser preview and whenever
///     the alarm asks for *any* object. The captured photo is accepted after a
///     short on-device "analysis" (the S3 + Gemini pipeline needs native +
///     cloud credentials that the web demo does not have).
class ObjectDetectionMission extends ConsumerStatefulWidget {
  const ObjectDetectionMission({
    super.key,
    required this.mission,
    required this.onVerified,
    required this.onFailed,
  });

  final AlarmMissionEntity mission;

  /// Invoked when the photo is accepted / verified.
  final VoidCallback onVerified;

  /// Invoked when verification fails (wrong object / low confidence / error).
  final ValueChanged<String> onFailed;

  @override
  ConsumerState<ObjectDetectionMission> createState() =>
      _ObjectDetectionMissionState();
}

enum _DetectPhase { idle, capturing, uploading, success, failure }

class _ObjectDetectionMissionState
    extends ConsumerState<ObjectDetectionMission> {
  final ImagePicker _picker = ImagePicker();

  _DetectPhase _phase = _DetectPhase.idle;
  ObjectDetectionResult? _lastResult;
  String? _errorMessage;
  bool _demoPassed = false;

  /// Consecutive backend/Gemini *errors* (not "wrong object"). After a few we
  /// let the user through, so a service outage can't trap them at the alarm.
  int _errorAttempts = 0;

  /// The resolved object to find this time, e.g. `keys`. When the alarm asks
  /// for "any" object we pick a random household item so each morning differs.
  late final String _effectiveTarget;

  /// True only in the web preview, where we show "any object" and accept any
  /// photo (no camera/Gemini pipeline available there).
  late final bool _isAnyDisplay;

  @override
  void initState() {
    super.initState();
    final configured = widget.mission.targetObject?.toLowerCase().trim();
    final hasSpecific = configured != null &&
        configured.isNotEmpty &&
        kSupportedDetectionObjects.contains(configured);

    if (hasSpecific) {
      _effectiveTarget = configured!;
      _isAnyDisplay = false;
    } else if (kIsWeb) {
      // Web demo: keep the lightweight "any object" experience.
      _effectiveTarget = 'any object';
      _isAnyDisplay = true;
    } else {
      // Native + "any": pick a random household object and really verify it.
      _effectiveTarget = kSupportedDetectionObjects[
          math.Random().nextInt(kSupportedDetectionObjects.length)];
      _isAnyDisplay = false;
    }
  }

  /// Demo mode runs entirely on-device (no Gemini): only the web preview.
  bool get _useDemo => _isAnyDisplay;

  Future<void> _captureAndVerify() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _phase = _DetectPhase.capturing;
      _errorMessage = null;
    });

    final XFile? shot;
    try {
      shot = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1280,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );
    } catch (_) {
      setState(() {
        _phase = _DetectPhase.failure;
        _errorMessage = l10n.missionCameraOpenError;
      });
      widget.onFailed(_errorMessage!);
      return;
    }

    if (shot == null) {
      // User cancelled — return to idle, no failure recorded.
      setState(() => _phase = _DetectPhase.idle);
      return;
    }

    setState(() => _phase = _DetectPhase.uploading);

    if (_useDemo) {
      // On-device "analysis" — accept any captured photo.
      await Future<void>.delayed(const Duration(milliseconds: 1300));
      if (!mounted) return;
      setState(() {
        _phase = _DetectPhase.success;
        _demoPassed = true;
      });
      Future<void>.delayed(const Duration(milliseconds: 700), () {
        if (mounted) widget.onVerified();
      });
      return;
    }

    final bytes = await shot.readAsBytes();
    final VerifyObject verify = ref.read(verifyObjectProvider);
    final result = await verify(
      VerifyObjectParams(
        bytes: bytes,
        targetObject: _effectiveTarget,
        contentType: 'image/jpeg',
      ),
    );

    if (!mounted) return;
    result.fold(
      (failure) {
        // A backend/Gemini error (not a "wrong object" verdict). Don't let a
        // service outage trap the user at the alarm: after a few failures,
        // accept and let them through.
        _errorAttempts++;
        if (_errorAttempts >= 3) {
          setState(() {
            _phase = _DetectPhase.success;
            _demoPassed = true;
            _errorMessage = null;
          });
          Future<void>.delayed(const Duration(milliseconds: 700), () {
            if (mounted) widget.onVerified();
          });
          return;
        }
        setState(() {
          _phase = _DetectPhase.failure;
          _errorMessage = failure.message;
        });
        widget.onFailed(failure.message);
      },
      (detection) {
        // A clean verdict from the AI resets the error streak.
        _errorAttempts = 0;
        setState(() {
          _lastResult = detection;
          _phase =
              detection.isMatch ? _DetectPhase.success : _DetectPhase.failure;
        });
        if (detection.isMatch) {
          Future<void>.delayed(const Duration(milliseconds: 600), () {
            if (mounted) widget.onVerified();
          });
        } else {
          widget.onFailed(
            l10n.missionDoesNotLookLike(_localizedTargetName(l10n)),
          );
        }
      },
    );
  }

  /// Localized display name for [_effectiveTarget] (English key → user's
  /// language), falling back to the raw key upper-cased.
  String _localizedTargetName(AppLocalizations l10n) {
    switch (_effectiveTarget) {
      case 'toothbrush':
        return l10n.objToothbrush;
      case 'sink':
        return l10n.objSink;
      case 'coffee mug':
        return l10n.objCoffeeMug;
      case 'keys':
        return l10n.objKeys;
      case 'shoes':
        return l10n.objShoes;
      case 'laptop':
        return l10n.objLaptop;
      default:
        return _effectiveTarget.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final color = switch (_phase) {
      _DetectPhase.success => Colors.green,
      _DetectPhase.failure => theme.colorScheme.error,
      _ => theme.colorScheme.primary,
    };

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_iconForPhase(), size: 96, color: color),
          const SizedBox(height: 24),
          Text(
            _isAnyDisplay
                ? l10n.missionPointCameraAt
                : l10n.missionTakePhotoOfYour,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          Text(
            _isAnyDisplay ? l10n.missionAnyObject : _localizedTargetName(l10n),
            style: theme.textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildStatusArea(theme),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isBusy ? null : _captureAndVerify,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: _isBusy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.camera_alt),
              label: Text(_buttonLabel()),
            ),
          ),
        ],
      ),
    );
  }

  bool get _isBusy =>
      _phase == _DetectPhase.capturing || _phase == _DetectPhase.uploading;

  IconData _iconForPhase() {
    return switch (_phase) {
      _DetectPhase.success => Icons.check_circle,
      _DetectPhase.failure => Icons.error_outline,
      _ => Icons.camera_alt_outlined,
    };
  }

  String _buttonLabel() {
    final l10n = AppLocalizations.of(context);
    return switch (_phase) {
      _DetectPhase.capturing => l10n.missionOpeningCamera,
      _DetectPhase.uploading => l10n.missionAnalyzing,
      _DetectPhase.failure => l10n.missionTryAgain,
      _DetectPhase.success => l10n.missionVerified,
      _DetectPhase.idle => l10n.missionOpenCamera,
    };
  }

  Widget _buildStatusArea(ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    if (_phase == _DetectPhase.uploading) {
      return Column(
        children: [
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
          Text(
            _useDemo
                ? l10n.missionAnalyzingYourPhoto
                : l10n.missionUploadingAndChecking,
            style: theme.textTheme.bodySmall,
          ),
        ],
      );
    }

    if (_demoPassed) {
      return Text(
        l10n.missionObjectDetected,
        style: theme.textTheme.titleMedium?.copyWith(color: Colors.green),
        textAlign: TextAlign.center,
      );
    }

    final result = _lastResult;
    if (result != null) {
      final color = result.isMatch ? Colors.green : theme.colorScheme.error;
      return Column(
        children: [
          Text(
            result.isMatch
                ? l10n.missionConfirmedSure(result.confidencePercent)
                : l10n.missionNotDetectedConfidence(result.confidencePercent),
            style: theme.textTheme.titleMedium?.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
          if (result.detectedObjects.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              l10n.missionSaw(result.detectedObjects.take(5).join(', ')),
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      );
    }

    if (_errorMessage != null) {
      return Text(
        _errorMessage!,
        style:
            theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
        textAlign: TextAlign.center,
      );
    }

    return Text(
      _isAnyDisplay ? l10n.missionAnyObjectHint : l10n.missionSpecificObjectHint,
      style: theme.textTheme.bodyMedium,
      textAlign: TextAlign.center,
    );
  }
}
