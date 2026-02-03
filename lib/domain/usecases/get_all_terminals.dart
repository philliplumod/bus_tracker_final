import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/terminal.dart';
import '../repositories/route_repository.dart';

class GetAllTerminals {
  final RouteRepository repository;

  GetAllTerminals(this.repository);

  Future<Either<Failure, List<Terminal>>> call() async {
    return await repository.getAllTerminals();
  }
}
