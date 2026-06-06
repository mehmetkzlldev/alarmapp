import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/alarm_entity.dart';
import '../repositories/alarm_repository.dart';

/// Toggles an alarm's active flag and (re-)arms or cancels the native trigger.
class ToggleAlarm implements UseCase<AlarmEntity, ToggleAlarmParams> {
  const ToggleAlarm(this._repository);

  final AlarmRepository _repository;

  @override
  Future<Either<Failure, AlarmEntity>> call(ToggleAlarmParams params) {
    return _repository.toggleAlarm(params.id);
  }
}

class ToggleAlarmParams extends Equatable {
  const ToggleAlarmParams({required this.id});

  final String id;

  @override
  List<Object?> get props => [id];
}
