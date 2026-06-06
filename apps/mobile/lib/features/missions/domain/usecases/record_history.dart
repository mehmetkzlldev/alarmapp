import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/mission_history.dart';
import '../repositories/missions_repository.dart';

/// Records the outcome of a mission attempt via `POST /missions/history`.
///
/// This is intentionally fire-and-forget-friendly: callers may ignore the
/// result. Recording history must never block alarm dismissal, so the provider
/// awaits it opportunistically and swallows failures.
class RecordHistory implements UseCase<MissionHistory, RecordHistoryParams> {
  const RecordHistory(this._repository);

  final MissionsRepository _repository;

  @override
  Future<Either<Failure, MissionHistory>> call(RecordHistoryParams params) {
    return _repository.recordHistory(params);
  }
}
