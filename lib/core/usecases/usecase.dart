import 'package:dartz/dartz.dart';
import '../error/failure.dart';

/// Abstract base for all use cases.
/// [Type] is the return type on success.
/// [Params] are the input parameters.
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Use this when a UseCase requires no parameters.
class NoParams {
  const NoParams();
}
