import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/alarm_repository.dart';

/// Deletes an alarm and cancels its native triggers.
class DeleteAlarm implements UseCase<Unit, DeleteAlarmParams> {
  const DeleteAlarm(this._repository);

  final AlarmRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(DeleteAlarmParams params) {
    return _repository.deleteAlarm(params.id);
  }
}

class DeleteAlarmParams extends Equatable {
  const DeleteAlarmParams({required this.id});

  final String id;

  @override
  List<Object?> get props => [id];
}
