import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/alarm_entity.dart';
import '../repositories/alarm_repository.dart';

/// Fetches all of the current user's alarms (network-first, cache-fallback).
class GetAlarms implements UseCase<List<AlarmEntity>, NoParams> {
  const GetAlarms(this._repository);

  final AlarmRepository _repository;

  @override
  Future<Either<Failure, List<AlarmEntity>>> call(NoParams params) {
    return _repository.getAlarms();
  }
}
