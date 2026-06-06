import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/alarm_entity.dart';
import '../repositories/alarm_repository.dart';

/// Updates an existing alarm and re-arms the native scheduler.
class UpdateAlarm implements UseCase<AlarmEntity, UpdateAlarmParams> {
  const UpdateAlarm(this._repository);

  final AlarmRepository _repository;

  @override
  Future<Either<Failure, AlarmEntity>> call(UpdateAlarmParams params) {
    return _repository.updateAlarm(params.alarm);
  }
}

class UpdateAlarmParams extends Equatable {
  const UpdateAlarmParams({required this.alarm});

  final AlarmEntity alarm;

  @override
  List<Object?> get props => [alarm];
}
