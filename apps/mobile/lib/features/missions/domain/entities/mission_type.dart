import 'package:equatable/equatable.dart';

/// Shared, wire-aligned vocabulary for mission kinds and difficulty.
///
/// This file is the single source of truth for [MissionKind] and
/// [MissionDifficulty] across the whole app — the alarms feature imports and
/// re-exports these enums, so DO NOT rename the members or their [wireValue]s
/// without updating the backend contract.
///
/// Pure domain: no JSON here. The data layer (`MissionTypeModel`) handles
/// (de)serialization and maps to/from these entities.

/// The kinds of missions the app knows how to render.
///
/// The [wireValue] strings are the `missionType` discriminators used across
/// every missions endpoint (`/alarms/:id/missions`, `/missions/history`,
/// `/ai-missions/...`).
enum MissionKind {
  math('math'),
  shake('shake'),
  objectDetection('object_detection');

  const MissionKind(this.wireValue);

  /// The exact string used on the wire (camelCase JSON, snake_case value).
  final String wireValue;

  /// Parse a wire value into a [MissionKind], returning `null` when the server
  /// sends a type this client build does not yet understand (forward compat).
  static MissionKind? fromWire(String? value) {
    for (final kind in MissionKind.values) {
      if (kind.wireValue == value) return kind;
    }
    return null;
  }

  /// Default, human-readable label. Presentation may localize separately.
  String get label => switch (this) {
        MissionKind.math => 'Math',
        MissionKind.shake => 'Shake',
        MissionKind.objectDetection => 'Photo',
      };
}

/// Difficulty levels shared by every mission type.
///
/// The wire value is the lowercase name. The backend uses these to scale math
/// operand counts, shake targets, and object-detection strictness.
enum MissionDifficulty {
  easy,
  medium,
  hard;

  String get wireValue => name;

  static MissionDifficulty fromWire(String? value) {
    return MissionDifficulty.values.firstWhere(
      (d) => d.name == value,
      orElse: () => MissionDifficulty.medium,
    );
  }
}

/// Pure domain entity describing a mission *type* available in the app.
///
/// Mirrors the shape returned by `GET /missions/types`. The backend owns the
/// canonical list; this wrapper keeps values strongly typed while tolerating
/// unknown server values (forward compatibility via a nullable [kind]).
class MissionType extends Equatable {
  const MissionType({
    required this.kind,
    required this.displayName,
    required this.description,
    required this.premiumOnly,
    this.supportedTargets = const <String>[],
  });

  /// Strongly-typed kind. `null` if the server advertised an unknown type —
  /// callers should filter those out before rendering.
  final MissionKind? kind;

  final String displayName;
  final String description;

  /// Whether this mission requires an active subscription.
  final bool premiumOnly;

  /// For object-detection missions, the list of valid target objects.
  /// Empty for other mission kinds.
  final List<String> supportedTargets;

  @override
  List<Object?> get props =>
      [kind, displayName, description, premiumOnly, supportedTargets];
}
