import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../error/failures.dart';

/// Contract for every use case in the app.
///
/// [Type] is the success payload; [Params] is the input. Use cases return an
/// [Either] so callers explicitly handle the [Failure] (left) or value (right).
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Marker for use cases that take no parameters.
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
