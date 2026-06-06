import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/alarm_entity.dart';
import '../repositories/alarm_repository.dart';

/// Creates a new alarm. The repository persists it, caches it, and registers it
/// with the native scheduler.
class CreateAlarm implements UseCase<AlarmEntity, CreateAlarmParams> {
  const CreateAlarm(this._repository);

  final AlarmRepository _repository;

  @override
  Future<Either<Failure, AlarmEntity>> call(CreateAlarmParams params) {
    return _repository.createAlarm(params.alarm);
  }
}

class CreateAlarmParams extends Equatable {
  const CreateAlarmParams({required this.alarm});

  final AlarmEntity alarm;

  @override
  List<Object?> get props => [alarm];
}
